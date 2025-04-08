import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void startForegroundTask() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Fetch the user's current circle
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final circleId = userDoc.data()?['currentCircleId'] as String?;
    if (circleId == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await FirebaseFirestore.instance
          .collection('circles')
          .doc(circleId)
          .collection('locations')
          .doc(userId)
          .set({
        'userId': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      sendPort?.send({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      print('Location update failed: $e');
    }
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button presses if needed
    print('Button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    // Handle notification tap
    print('Notification pressed');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }

  @override
  Future<void> onDestroy(DateTime timestamp) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) {
    // TODO: implement onStart
    throw UnimplementedError();
  }
}
