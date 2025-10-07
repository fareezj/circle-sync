import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart';

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

  /// Simulated movement along a path (like walking around KL city center)
  Stream<Position> _simulatePositionStream() async* {
    // Kuala Lumpur city center coordinates
    List<LatLng> waypoints = [
      LatLng(3.1390, 101.6869), // KLCC
      LatLng(3.1478, 101.6953), // Pavilion KL
      LatLng(3.1516, 101.7020), // Bukit Bintang
      LatLng(3.1570, 101.7120), // Times Square
      LatLng(3.1480, 101.7000), // Lot 10
      LatLng(3.1420, 101.6920), // Back towards KLCC
    ];

    int currentWaypointIndex = 0;
    LatLng currentPos = waypoints[0];

    while (true) {
      await Future.delayed(const Duration(seconds: 3));

      // Move towards the next waypoint
      LatLng target = waypoints[currentWaypointIndex % waypoints.length];

      // Calculate movement step (simulate walking speed)
      double stepSize = 0.0001; // ~11 meters per step
      double latDiff = target.latitude - currentPos.latitude;
      double lngDiff = target.longitude - currentPos.longitude;
      double distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

      if (distance < stepSize) {
        // Reached waypoint, move to next one
        currentWaypointIndex++;
        currentPos = target;
      } else {
        // Move towards target
        double ratio = stepSize / distance;
        currentPos = LatLng(
          currentPos.latitude + (latDiff * ratio),
          currentPos.longitude + (lngDiff * ratio),
        );
      }

      // Add some natural variation
      double variation = 0.00002;
      double randomLat =
          currentPos.latitude + (Random().nextDouble() - 0.5) * variation;
      double randomLng =
          currentPos.longitude + (Random().nextDouble() - 0.5) * variation;

      yield Position(
        latitude: randomLat,
        longitude: randomLng,
        timestamp: DateTime.now(),
        accuracy: 5.0 + Random().nextDouble() * 5.0, // 5-10m accuracy
        altitude: 50.0 + Random().nextDouble() * 20.0,
        heading: 0.0,
        speed: 1.2 + Random().nextDouble() * 0.8, // 1.2-2.0 m/s (walking speed)
        speedAccuracy: 0.5,
        altitudeAccuracy: 3.0,
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
    print('Supabase current user: ${user?.id}');
    if (user == null) {
      print('ERROR: No Supabase user authenticated!');
      return;
    }
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
      final locationSource = _useSimulation ? '🎮 SIMULATED' : '📍 REAL GPS';
      print(
          '$locationSource Position update: ${pos.latitude}, ${pos.longitude}');
      final updated = LatLng(pos.latitude, pos.longitude);
      onLocationUpdate(updated, [updated]);

      if (_isLocationSharing) {
        print('💾 Saving $locationSource location to database...');
        await upsertLocation(circleId, uid, updated, false);
      } else {
        print('⏸️ Location sharing disabled - not saving to database');
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
      print(
          '💾 Updating location in DB - Circle: $circleId, User: ${userId.substring(0, 8)}...');
      print(
          '📍 Location: ${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}');

      final result = await _supabase.from('locations').upsert(
        {
          'circle_id': circleId,
          'user_id': userId,
          'lat': loc.latitude,
          'lng': loc.longitude,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'circle_id, user_id',
      ).select();

      print(
          '✅ Location saved to database successfully! Rows affected: ${result.length}');
    } on PostgrestException catch (e) {
      print('❌ Location upsert error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error saving location: $e');
    }
  }

  /// Stream other members' locations in real time
  void subscribeToOtherUsersLocations({
    required String circleId,
    required String currentUserId, // Add this parameter to match map_page.dart
    required Function(Map<String, LatLng>) onLocationsUpdate,
  }) {
    _realtimeSubscription = _supabase
        .from('locations') // 1) subscribe to the table
        .stream(primaryKey: [
          'id'
        ]) // 2) tell it what your PK is (matches DB schema)
        .eq('circle_id', circleId) // 3) apply your filter
        .listen((rows) {
          print('🎯 Real-time location update received: ${rows.length} rows');
          final Map<String, LatLng> updated = {};

          for (final row in rows as List) {
            final rowUid = row['user_id'] as String;
            print('  📍 User: $rowUid, Current: $currentUserId');
            if (rowUid == currentUserId) {
              print('  ⏭️ Skipping own location');
              continue; // Skip current user
            }
            final lat = (row['lat'] as num).toDouble();
            final lng = (row['lng'] as num).toDouble();
            updated[rowUid] = LatLng(lat, lng);
            print('  ✅ Added location for $rowUid: $lat, $lng');
          }
          print('🗺️ Final other user locations map: $updated');
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
