import 'dart:async';
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
void startCallback() {
  print('Foreground task callback triggered');
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Foreground task started at $timestamp');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service not enabled');
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Location Error',
          notificationText: 'Please enable location services',
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('Location permission not granted');
          await FlutterForegroundTask.updateService(
            notificationTitle: 'Location Error',
            notificationText: 'Please grant location permissions',
          );
          return;
        }
      }
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        String notificationText =
            'Lat: ${position.latitude}, Lon: ${position.longitude} at ${DateTime.now().toIso8601String()}';
        FlutterForegroundTask.updateService(
          notificationTitle: 'Location Update',
          notificationText: notificationText,
        );
        print('Location: ${position.latitude}, ${position.longitude}');
      });
      print('Location stream initialized');
    } catch (e) {
      print('Error initializing location: $e');
    }
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
