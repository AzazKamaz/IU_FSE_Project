import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:automated_attendance_app/providers/oauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class StudentAttendances extends StatefulWidget {
  StudentAttendances({Key key}) : super(key: key);

  @override
  _StudentAttendances createState() => _StudentAttendances();
}

class _StudentAttendances extends State<StudentAttendances>
    with AutomaticKeepAliveClientMixin<StudentAttendances> {
  Snapshot<dynamic> attendances;

  @override
  initState() {
    super.initState();

    final me = Provider.of<OauthModel>(context, listen: false).userId;
    print('student_attendances');
    attendances = HasuraModel.get(context).subscription("""
      subscription(\$me: uuid!) {
        attendances(where: {user_id: {_eq: \$me}}, order_by: {class: {starts_at: desc}}) {
          first_seen_at
          last_seen_at
          class {
            title
            teacher {
              name
              email
            }
            starts_at
            ends_at
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
            ? snapshot.data["data"]["attendances"] as List<dynamic>
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
    String teacherName = attendance["class"]["teacher"]["name"];
    String teacherEmail = attendance["class"]["teacher"]["email"];

    DateTime classStarts = DateTime.parse(attendance["class"]["starts_at"]);
    DateTime classEnds = DateTime.parse(attendance["class"]["ends_at"]);

    DateTime firstSeen = DateTime.parse(attendance["first_seen_at"]);
    DateTime lastSeen = DateTime.parse(attendance["last_seen_at"]);

    double percent = classStarts == classEnds
        ? 0
        : lastSeen.difference(firstSeen).inSeconds /
            classEnds.difference(classStarts).inSeconds;
    return ListTile(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(
            attendance["class"]["title"],
            style: Theme.of(context).textTheme.headline6,
          ),
          Text(' '),
          Text(
            formatDateTime(classStarts),
            style: Theme.of(context).textTheme.subtitle1,
          )
        ],
      ),
      subtitle: Text('$teacherName, $teacherEmail'),
      trailing: percent > .95
          ? Icon(
              Icons.check_circle_outline,
              size: Theme.of(context).textTheme.headline4.fontSize,
              color: Colors.green,
            )
          : Text(
              NumberFormat.percentPattern().format(percent),
              style: Theme.of(context).textTheme.headline4,
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
