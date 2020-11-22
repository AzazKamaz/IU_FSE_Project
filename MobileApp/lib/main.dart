import 'package:automated_attendance_app/providers/hasura.dart';
import 'package:automated_attendance_app/providers/oauth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/login.dart';
import 'pages/attendance.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => HasuraModel()),
      ChangeNotifierProxyProvider<HasuraModel, OauthModel>(
        update: (context, hasura, oauth) => OauthModel(hasura),
        create: (BuildContext context) => null,
      ),
    ],
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
        primarySwatch: Colors.green,
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
