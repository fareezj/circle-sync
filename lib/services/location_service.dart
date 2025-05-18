import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class LocationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  bool _useSimulation = false;
  bool _isLocationSharing = true;

  /// Expose sharing state
  bool get isLocationSharing => _isLocationSharing;

  /// Initialize a single static location
  Future<void> initStaticLocation({
    required Function(LatLng) onLocationUpdate,
    required Function(List<LatLng>) onTrackingUpdate,
  }) async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    LatLng current;
    List<LatLng> trackingPoints;
    if (!_useSimulation) {
      var pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      current = LatLng(pos.latitude, pos.longitude);
      trackingPoints = [current];
    } else {
      current = LatLng(37.7749, -122.4194);
      trackingPoints = [current];
    }

    onLocationUpdate(current);
    onTrackingUpdate(trackingPoints);
  }

  /// Initialize starting location, destination, and route
  Future<void> initInitialLocationAndRoute({
    required Function(LatLng, LatLng, List<LatLng>) onLocationAndRouteUpdate,
  }) async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    LatLng current;
    LatLng destination;

    if (!_useSimulation) {
      var pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      current = LatLng(pos.latitude, pos.longitude);
      destination = LatLng(pos.latitude + 0.01, pos.longitude + 0.01);
    } else {
      current = LatLng(3.0625016, 101.6682533);
      destination = LatLng(3.0725016, 101.6982533);
    }

    onLocationAndRouteUpdate(current, destination, [current]);
  }

  /// Simulated circular movement
  Stream<Position> _simulatePositionStream() async* {
    double lat = 3.0625016;
    double lng = 101.6682533;
    int step = 0;

    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      step++;
      double angle = step * 0.1;
      lat += 0.001 * cos(angle);
      lng += 0.001 * sin(angle);

      yield Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 1.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  }

  /// Subscribe to user position updates and sync to Supabase
  Future<void> subscribeToLocationUpdates({
    required String circleId,
    required bool useSimulation,
    required Function(LatLng, List<LatLng>) onLocationUpdate,
  }) async {
    print('useSimulation: $useSimulation');
    _useSimulation = useSimulation;
    await _positionStreamSubscription?.cancel();

    // Ensure current user
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final uid = user.id;

    Stream<Position> posStream = _useSimulation
        ? _simulatePositionStream()
        : Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 10,
            ),
          );

    _positionStreamSubscription = posStream.listen((pos) async {
      print('Position update: ${pos.latitude}, ${pos.longitude}');
      final updated = LatLng(pos.latitude, pos.longitude);
      onLocationUpdate(updated, [updated]);

      if (_isLocationSharing) {
        await upsertLocation(circleId, uid, updated, false);
      }
    });
  }

  /// Upsert a location row in Supabase
  Future<void> upsertLocation(
    String circleId,
    String userId,
    LatLng loc,
    bool isPaused,
  ) async {
    try {
      print('updating location circleId: $circleId, userId: $userId');
      print('updating location lat: ${loc.latitude}, lng: ${loc.longitude}');
      await _supabase.from('locations').upsert(
        {
          'location_id': Uuid().v4(),
          'created_at': DateTime.now().toIso8601String(),
          'circle_id': circleId,
          'user_id': userId,
          'lat': loc.latitude,
          'lng': loc.longitude,
          'is_paused': isPaused,
        },
        onConflict: 'circle_id, user_id',
      ).select();
    } on PostgrestException catch (e) {
      print('Location upsert error: ${e.message}');
    }
  }

  /// Stream other members’ locations in real time
  void subscribeToOtherUsersLocations({
    required String circleId,
    required Function(Map<String, LatLng>) onLocationsUpdate,
  }) {
    _realtimeSubscription = _supabase
        .from('locations') // 1) subscribe to the table
        .stream(primaryKey: ['location_id']) // 2) tell it what your PK is
        .eq('circle_id', circleId) // 3) apply your filter
        .listen((rows) {
          print('listening: $rows');
          final Map<String, LatLng> updated = {};
          final uid = _supabase.auth.currentUser?.id;

          for (final row in rows as List) {
            final rowUid = row['user_id'] as String;
            if (rowUid == uid) continue;
            updated[rowUid] = LatLng(
              (row['lat'] as num).toDouble(),
              (row['lng'] as num).toDouble(),
            );
          }
          print('Updated locations: $updated');
          onLocationsUpdate(updated);
        });
  }

  /// Pause sharing: mark last known and pause
  Future<void> pauseLocationSharing(
    String circleId,
    LatLng? lastKnown,
  ) async {
    _isLocationSharing = false;
    final user = _supabase.auth.currentUser;
    if (user == null || lastKnown == null) return;
    await upsertLocation(circleId, user.id, lastKnown, true);
  }

  /// Resume sharing
  Future<void> resumeLocationSharing(
    String circleId,
    LatLng? lastKnown,
  ) async {
    _isLocationSharing = true;
    final user = _supabase.auth.currentUser;
    if (user == null || lastKnown == null) return;
    await upsertLocation(circleId, user.id, lastKnown, false);
  }

  /// Foreground task start
  Future<void> startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Circle Sync Running',
      notificationText: 'Sharing your location',
      callback: startForegroundTask,
    );
    final port = FlutterForegroundTask.receivePort;
    if (port != null) {
      port.listen((data) {
        // handle background updates if needed
      });
    }
  }

  /// Stop foreground task
  Future<void> stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
  }

  /// Cleanup
  void dispose() {
    _positionStreamSubscription?.cancel();
    _realtimeSubscription?.cancel();
    stopForegroundTask();
  }
}
