import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:automated_attendance_app/providers/oauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_ble_peripheral/data.dart';
import 'package:flutter_ble_peripheral/main.dart';

// import 'package:hasura_connect/hasura_connect.dart';
import 'package:hasura/hasura.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/hasura.dart';
import '../utils.dart';
import 'class_attendance.dart';

class TeacherClasses extends StatefulWidget {
  TeacherClasses({Key key}) : super(key: key);

  @override
  _TeacherClasses createState() => _TeacherClasses();
}

class _TeacherClasses extends State<TeacherClasses>
    with AutomaticKeepAliveClientMixin<TeacherClasses> {
  Snapshot<dynamic> attendances;

  @override
  initState() {
    super.initState();

    final me = Provider.of<OauthModel>(context, listen: false).userId;
    print('teacher_classes');
    attendances = HasuraModel.get(context).subscription("""
      subscription(\$me: uuid!) {
        classes(where: {teacher_id: {_eq: \$me}}, order_by: {starts_at: desc}) {
          id
          title
          starts_at
          attendances_aggregate {
            aggregate {
              count
            }
          }
        }
      }
    """, variables: {'me': me});
  }

  @override
  Future<void> dispose() async {
    attendances?.close();
    super.dispose();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    final userId = Provider.of<OauthModel>(context).userId;
    attendances?.changeVariable({"me": userId});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder(
      stream: attendances?.asBroadcastStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active)
          return Container();
        print(snapshot);
        var attendances = snapshot.hasData
            ? snapshot.data["data"]["classes"] as List<dynamic>
            : [];
        return ListView(
          padding: EdgeInsets.all(16.0),
          children: ListTile.divideTiles(
            context: context,
            tiles: attendances.map(this.listEntry),
          ).toList(),
        );
      },
    );
  }

  Widget listEntry(attendance) {
    DateTime classStarts = DateTime.parse(attendance["starts_at"]);
    int count =
        attendance["attendances_aggregate"]["aggregate"]["count"];

    return ListTile(
      title: Text(
        attendance["title"],
        style: Theme.of(context).textTheme.headline6,
      ),
      subtitle: Text(
        formatDateTime(classStarts),
        style: Theme.of(context).textTheme.subtitle1,
      ),
      trailing: Text(
        count.toString(),
        style: Theme.of(context).textTheme.headline4,
      ),
      onTap: () => showClassAttendance(context, attendance['id']),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
