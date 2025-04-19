import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

class LocationTask {
  static void initForegroundTask() {
    print('Initializing foreground task');
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_channel',
        channelName: 'Location Updates',
        channelDescription: 'This notification shows location updates.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
        eventAction: ForegroundTaskEventAction.repeat(5000),
      ),
    );
  }

  static Future<void> startForegroundTask() async {
    print('Starting foreground service');
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Location Tracking',
        notificationText: 'Tracking your location continuously',
        callback: startCallback,
      );
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Tracking',
        notificationText: 'Service started at ${DateTime.now()}',
      );
      print('Foreground service started');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  static Future<void> stopForegroundTask() async {
    print('Stopping foreground service');
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
Future<void> startCallback() async {
  // 1) Ensure that background plugins can be called
  DartPluginRegistrant.ensureInitialized();
  // 2) Bring up the Flutter bindings in this isolate
  WidgetsFlutterBinding.ensureInitialized();
  // 3) Initialize Firebase in this isolate
  await Firebase.initializeApp();
  // 4) Now register your task handler
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  List<String> _circleIds = [];

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Foreground task started at $timestamp');
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 1. Ensure location services & permissions as before…
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Error',
        notificationText: 'Please enable location services',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Error',
        notificationText: 'Please grant location permissions',
      );
      return;
    }

    // 2. Fetch all circles this user belongs to (once at startup)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user – cannot fetch circles.');
      return;
    }
    final userId = user.uid;

    final circlesSnap = await firestore
        .collection('circles')
        .where('members', arrayContains: userId)
        .get();

    _circleIds = circlesSnap.docs.map((d) => d.id).toList();
    print('Joined circles: $_circleIds');

    // 3. Listen for location updates and write to each circle’s sub‑collection
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      final data = {
        'userId': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isPaused': false,
      };

      // Batch all writes into one commit
      final batch = firestore.batch();
      for (final circleId in _circleIds) {
        final locRef = firestore
            .collection('circles')
            .doc(circleId)
            .collection('locations')
            .doc(userId);
        batch.set(locRef, data, SetOptions(merge: true));
      }
      await batch.commit();

      // Update notification
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Update',
        notificationText:
            'Lat: ${position.latitude}, Lon: ${position.longitude}',
      );

      print('Batched location update for ${_circleIds.length} circles.');
    });

    print('Location stream initialized');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    print('Foreground task event at $timestamp');
    if (_positionSubscription == null) {
      print('Location stream not initialized');
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Error',
        notificationText: 'Location stream not initialized',
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('Foreground task destroyed at $timestamp');
    await _positionSubscription?.cancel();
  }

  @override
  void onButtonPressed(String id) {
    if (id == 'stop') {
      LocationTask.stopForegroundTask();
    }
  }
}
