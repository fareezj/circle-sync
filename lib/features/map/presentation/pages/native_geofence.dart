import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:circle_sync/features/map/presentation/pages/widgets/create_geofence.dart';
import 'package:flutter/material.dart';

import 'package:native_geofence/native_geofence.dart';

class NativeGeofence extends StatefulWidget {
  const NativeGeofence({super.key});

  @override
  _NativeGeofenceState createState() => _NativeGeofenceState();
}

class _NativeGeofenceState extends State<NativeGeofence> {
  String geofenceState = 'N/A';
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'native_geofence_send_port',
    );
    port.listen((dynamic data) {
      debugPrint('Event: $data');
      setState(() {
        geofenceState = data;
      });
    });
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    debugPrint('Initializing...');
    await NativeGeofenceManager.instance.initialize();
    debugPrint('Initialization done');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Geofence'),
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Current state: $geofenceState'),
                const SizedBox(height: 20),
                CreateGeofence(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
