import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:automated_attendance_app/oauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_ble_peripheral/data.dart';
import 'package:flutter_ble_peripheral/main.dart';
import 'package:hasura_connect/hasura_connect.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'hasura.dart';

class AttendancePage extends StatefulWidget {
  AttendancePage({Key key}) : super(key: key);

  @override
  _AttendancePage createState() => _AttendancePage();
}

class _AttendancePage extends State<AttendancePage> {
  PermissionStatus locationPermissionStatus = PermissionStatus.unknown;
  final BleManager bleManager = BleManager();
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  String accessToken;
  Map<String, String> students = Map();

  Snapshot<dynamic> myAttendanceSnapshot;
  Snapshot<dynamic> myAttendeesSnapshot;

  @override
  initState() {
    super.initState();

    bleManager.createClient().then((_) async {
      await _checkPermissions();

      await bleManager.stopPeripheralScan();

      bleManager.startPeripheralScan().listen((peripheral) async {
        if (accessToken != null &&
            peripheral.advertisementData?.serviceUuids?.length == 1) {
          final student = peripheral.advertisementData.serviceUuids[0];
          print('attend/$student');
        }
      });
    });

    hasura.subscription("""
      subscription(\$me: uuid!) {
        attendances(where: {user_id: {_eq: \$me}}) {
          class {
            title
            teacher: user {
              name
              email
            }
          }
        }
      }
    """, variables: {
      "me": "10fb17c8-a2e7-40ba-bb13-13e0f92e4e74",
    }).then((value) {
      setState(() {
        myAttendanceSnapshot = value;
      });
    });

    hasura.subscription("""
      subscription {
        attendances(where: {class_id: {_eq: "3cfd889b-8713-4713-a8ae-c4e909233d95"}}) {
          user {
            name
            email
            id
          }
        }
      }
    """).then((value) {
      setState(() {
        myAttendeesSnapshot = value;
      });
    });
  }

  @override
  Future<void> dispose() async {
    myAttendanceSnapshot?.close();
    myAttendeesSnapshot?.close();

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
    final user = Provider.of<OauthModel>(context).user;

    // myAttendanceSnapshot?.changeVariables({"me": user["id"]});

    if (await blePeripheral.isAdvertising()) await blePeripheral.stop();

    AdvertiseData data = AdvertiseData();

    data.includeDeviceName = false;
    data.uuid = user['oid'];

    await blePeripheral.start(data);
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Provider.of<OauthModel>(context).user["name"]),
          bottom: TabBar(
            tabs: [
              Tab(text: "My Attendances"),
              Tab(text: "My Attendees"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildAttendanceList(), _buildAttendeesList()],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder(
      stream: myAttendanceSnapshot?.rootStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active)
          return Container();
        print(snapshot);
        var attendances = snapshot.data["data"]["attendances"] as List<dynamic>;
        return ListView(
          padding: EdgeInsets.all(16.0),
          children: ListTile.divideTiles(
            context: context,
            tiles: attendances.map((student) => ListTile(
                title: Text(
                  student["class"]["title"],
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Text(student["class"]["teacher"]["name"]),
                trailing: Icon(
                  Icons.check_circle,
                  color: true ? Colors.green : Colors.red,
                ))),
          ).toList(),
        );
      },
    );
  }

  Widget _buildAttendeesList() {
    return StreamBuilder(
      stream: myAttendeesSnapshot?.rootStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active)
          return Container();
        var attendances = snapshot.data["data"]["attendances"] as List<dynamic>;
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
}
