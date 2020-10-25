import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:automated_attendance_app/oauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_ble_peripheral/data.dart';
import 'package:flutter_ble_peripheral/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

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
          await http
              .get(
                'http://10.91.55.167:8000/api/attend?jwt=$accessToken&student=$student&lesson=pupa',
                headers: {'Authorization': 'Bearer $accessToken'},
              )
              .then((res) => jsonDecode(res.body))
              .then((student) {
                if (student['name'] != null)
                  setState(() {
                    students[student['email']] = student['name'];
                  });
              });
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
    final user = Provider.of<OauthModel>(context).user;

    if (await blePeripheral.isAdvertising()) await blePeripheral.stop();

    await http
        .get('http://10.91.55.167:8000/api/authorize?jwt=${token.idToken}');

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
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('Attendance'),
    //   ),
    //   body: ListView(
    //     children: students.entries
    //         .map((p) => ListTile(
    //               title: Text(p.value),
    //               subtitle: Text(p.key),
    //             ))
    //         .toList(),
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text('Innopolis University : FSE'),
      ),
      body: _buildAttendanceList(),
    );
  }

  Widget _buildAttendanceList() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: ListTile.divideTiles(
        context: context,
        tiles: students.entries
            .map((student) => ListTile(
                title: Text(
                  student.value,
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Text(student.key),
                trailing: Icon(
                  Icons.check_circle,
                  color: true ? Colors.green : Colors.red,
                ))),
      ).toList(),
    );
  }
}
