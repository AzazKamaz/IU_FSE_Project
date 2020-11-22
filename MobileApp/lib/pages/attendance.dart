import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:automated_attendance_app/providers/oauth.dart';
import 'package:automated_attendance_app/widgets/student_attendances.dart';
import 'package:automated_attendance_app/widgets/teacher_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_ble_peripheral/data.dart';
import 'package:flutter_ble_peripheral/main.dart';
import 'package:hasura/hasura.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/hasura.dart';

class AttendancePage extends StatefulWidget {
  AttendancePage({Key key}) : super(key: key);

  @override
  _AttendancePage createState() => _AttendancePage();
}

class _AttendancePage extends State<AttendancePage> {
  final BleManager bleManager = BleManager();
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  String accessToken;
  Map<String, DateTime> students = Map();
  Snapshot<dynamic> classes;

  @override
  initState() {
    super.initState();

    final me = Provider.of<OauthModel>(context, listen: false).userId;
    print('teacher_classes');
    classes = HasuraModel.get(context).subscription("""
      subscription(\$me: uuid!) {
        classes(where: {teacher_id: {_eq: \$me}}) {
          id
          starts_at
          ends_at
        }
      }
    """, variables: {'me': me});

    bleManager.createClient().then((_) async {
      await _checkPermissions();

      await bleManager.stopPeripheralScan();

      bleManager.startPeripheralScan().listen((peripheral) async {
        if (accessToken != null &&
            peripheral.advertisementData?.serviceUuids?.length == 1) {
          final student = peripheral.advertisementData.serviceUuids[0];
          if (students.containsKey(student) &&
              DateTime.now().difference(students[student]) <
                  Duration(minutes: 1)) return;

          students.addAll({student: DateTime.now()});

          print('attend/$student');

          final ongoingClasses = classes?.value['data']['classes'].where((c) =>
              DateTime.now().isAfter(DateTime.parse(c['starts_at'])) &&
              DateTime.now().isBefore(DateTime.parse(c['ends_at'])));

          for(var i in ongoingClasses)
            await HasuraModel.get(context).mutation(
                "mutation(\$class: uuid!, \$user: uuid!) {attend(class_id: \$class, user_id: \$user){success}}",
                variables: {
                  'class': i['id'],
                  'user': student,
                }).catchError(print);
        }
      });
    });
  }

  @override
  Future<void> dispose() async {
    await blePeripheral.stop();

    await bleManager.stopPeripheralScan();
    await bleManager.destroyClient();

    super.dispose();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    final token = Provider.of<OauthModel>(context).token;
    this.accessToken = token.idToken;
    final userId = Provider.of<OauthModel>(context).userId;
    classes?.changeVariable({"me": userId});

    if (await blePeripheral.isAdvertising()) await blePeripheral.stop();

    AdvertiseData data = AdvertiseData();

    data.includeDeviceName = false;
    data.uuid = userId;

    await blePeripheral.start(data);
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      PermissionStatus locationPermissionStatus = PermissionStatus.unknown;

      while (locationPermissionStatus != PermissionStatus.granted) {
        var permissionStatus = await PermissionHandler()
            .requestPermissions([PermissionGroup.location]);

        locationPermissionStatus = permissionStatus[PermissionGroup.location];
      }

      if (locationPermissionStatus != PermissionStatus.granted) {
        return Future.error(Exception("Location permission not granted"));
      }
    }
  }

  Widget appBarBackground(BuildContext context) {
    print(Provider.of<OauthModel>(context).user);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage:
              NetworkImage("https://thispersondoesnotexist.com/image"),
          radius: 90,
        ),
        SizedBox(height: 40),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder:
              (BuildContext context, bool innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  title: Text(Provider.of<OauthModel>(context).user["name"]),
                  centerTitle: true,
                  titlePadding: EdgeInsets.only(bottom: 62),
                  collapseMode: CollapseMode.pin,
                  background: appBarBackground(context)),
              expandedHeight: 300,
              bottom: TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: "My Attendances"),
                  Tab(text: "My Classes"),
                ],
              ),
            )
          ],
          body: TabBarView(
            children: [
              StudentAttendances(),
              TeacherClasses(),
            ],
          ),
        ),
      ),
    );
  }
}
