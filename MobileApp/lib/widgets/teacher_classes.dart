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
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/hasura.dart';

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
        attendances(where: {class: {teacher_id: {_eq: \$me}}}) {
          user {
            name
            email
            id
          }
        }
      }
    """, variables: {'me': me});
    //     .then((value) {
    //   // value.changeVariables(
    //       // {'me': Provider.of<OauthModel>(context, listen: false).userId});
    //   setState(() {
    //     attendances = value;
    //   });
    // });
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
    // if (attendances != null && attendances.query.variables["me"] != userId)
    //   attendances?.changeVariables({"me": userId});
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
            tiles: attendances?.map((student) => ListTile(
                title: Text(
                  student["user"]["name"].contains("Sherif")
                      ? "[zoom] " + student["user"]["name"]
                      : student["user"]["name"],
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Text(student["user"]["email"]),
                trailing: Icon(
                  Icons.check_circle,
                  color: true ? Colors.green : Colors.red,
                ))),
          ).toList(),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
