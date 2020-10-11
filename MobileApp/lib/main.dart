import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automated Attendance BLE Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'BLE Peripheral list'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PermissionStatus locationPermissionStatus = PermissionStatus.unknown;
  final BleManager bleManager = BleManager();
  final Map<String, MapEntry<DateTime, ScanResult>> peripherals = {};

  @override
  initState() {
    super.initState();

    bleManager.createClient().then((_) {
      print("Client created");
      clear();
    });
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

  Future<void> clear() async {
    await _checkPermissions();

    await bleManager.stopPeripheralScan();

    setState(() {
      peripherals.clear();
      print("Scanning...");
      bleManager.startPeripheralScan().listen((peripheral) {
        setState(() {
          peripherals[peripheral.peripheral.identifier] = MapEntry(DateTime.now(), peripheral);
        });
      });
    });
  }

  @override
  void dispose() {
    bleManager.destroyClient();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: peripherals.values.where((p) =>
          p.value.peripheral.name != null || p.value.advertisementData.serviceData != null || p.value.advertisementData.serviceUuids != null ||p.value.advertisementData.solicitedServiceUuids != null
        ).map((p) => ListTile(
          title: Text('[${p.value.peripheral.identifier}] ${p.value.peripheral.name ?? ''}'),
          subtitle: Column(
            children: [
              Column(
                children:
                p.value.advertisementData.serviceData?.entries?.map(
                        (service) => Text(service.value.length > 0
                        ? '[${service.key}] - ${String.fromCharCodes(service.value)}'
                        : '[${service.key}]'))?.toList() ?? [],
              ),
              Column(
                children: p.value.advertisementData.serviceUuids?.map((service) => Text(service))?.toList() ?? [],
              ),
              Column(
                children: p.value.advertisementData.solicitedServiceUuids?.map((service) => Text(service))?.toList() ?? [],
              )
            ],
          ),
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: clear,
        tooltip: 'Clear',
        child: Icon(Icons.clear),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
