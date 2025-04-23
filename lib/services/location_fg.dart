// location_task.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class LocationTask {
  /// Call once at app startup to configure the foreground-task plugin.
  static Future<void> initForegroundTask() async {
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

  /// Starts the foreground service, persisting [userId] and [circleIds]
  /// so they’re available inside the background isolate.
  static Future<void> startForegroundTask({
    required String userId,
    required List<String> circleIds,
  }) async {
    print('passed userId: $userId');
    print('passed circleIds: $circleIds');
    // Persist into the plugin’s key/value store
    await FlutterForegroundTask.saveData(key: 'userId', value: userId);
    await FlutterForegroundTask.saveData(
      key: 'circleIds',
      value: circleIds,
    );

    // Start the service; callback must be a top-level or static function
    await FlutterForegroundTask.startService(
      notificationTitle: 'Circle Sync Active',
      notificationText: 'Sharing your location…',
      callback: startCallback,
    );
  }

  /// Stops the foreground service.
  static Future<void> stopForegroundTask() =>
      FlutterForegroundTask.stopService();
}

/// This function is launched in the background isolate by the plugin.
/// It must be a top‐level or static function so it can be serialized.
@pragma('vm:entry-point')
Future<void> startCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Re‐initialize Supabase in this isolate
  await Supabase.initialize(
    url: 'https://hnbqegfgzwugkdtfysma.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuYnFlZ2Znend1Z2tkdGZ5c21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTE2NjQsImV4cCI6MjA2MDcyNzY2NH0.l_RqDcUmqvB_MRJ3VG-VQJcjVXqlKeQPghoEy5awTGc',
  );

  // Register our handler for task events
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  late final String _userId;
  late final List<String> _circleIds;
  final _supabase = Supabase.instance.client;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // 1) Retrieve the persisted userId
    _userId = await FlutterForegroundTask.getData<String>(key: 'userId') ?? '';
    if (_userId.isEmpty) {
      print('❌ Missing userId, cannot start');
      return;
    }

    // 2) Fetch circleIds from Supabase instead of saved data
    try {
      // Filter on the JSONB/array 'members' column
      final response = await Supabase.instance.client
          .from('circles')
          .select('circle_id')
          .contains('members', '["$_userId"]');
      print('awow: $response');

      // Cast and extract the IDs
      _circleIds =
          (response as List).map((r) => r['circle_id'] as String).toList();
      print('Fetched circles: $_circleIds');
    } catch (e) {
      print('Error fetching circles: $e');
      return;
    }

    if (_circleIds.isEmpty) {
      print('🔔 User isn’t in any circles – nothing to track');
      return;
    }

    // 3) Check permissions & services as before…
    if (!await Geolocator.isLocationServiceEnabled()) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Error',
        notificationText: 'Enable location services',
      );
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Error',
        notificationText: 'Grant location permission',
      );
      return;
    }

    Future<void> onPosition(Position pos) async {
      final lat = pos.latitude;
      final lng = pos.longitude;

      for (final circleId in _circleIds) {
        await _supabase.from('locations').upsert(
          {
            'circle_id': circleId,
            'user_id': _userId,
            'lat': lat,
            'lng': lng,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_paused': false,
          },
          onConflict:
              'circle_id,user_id', // atomic update/insert :contentReference[oaicite:5]{index=5}
        );
      }

      await FlutterForegroundTask.updateService(
        notificationTitle: 'Location Update',
        notificationText:
            'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
      );
    }

    // 4) Subscribe to the position stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(onPosition);

    // 5) Kick off the notification
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Circle Sync Active',
      notificationText: 'Sharing your location…',
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // no‐op; location stream is running continuously
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSubscription?.cancel();
  }

  @override
  void onButtonPressed(String id) {
    if (id == 'stop') {
      LocationTask.stopForegroundTask();
    }
  }
}
