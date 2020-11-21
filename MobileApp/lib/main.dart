import 'package:automated_attendance_app/login.dart';
import 'package:automated_attendance_app/oauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'login.dart';
import 'attendance.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => OauthModel(),
    child: AttendanceApp(),
  ));
}

class AttendanceApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AttendanceApp();
}

class _AttendanceApp extends State<AttendanceApp> {
  Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    var authorized = Provider.of<OauthModel>(context).user != null;

    return MaterialApp(
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Navigator(
        pages: [
          MaterialPage(
            key: ValueKey('login'),
            child: LoginPage(),
          ),
          if (authorized)
            MaterialPage(
              key: ValueKey('attendance'),
              child: AttendancePage(),
            ),
        ],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }
}
