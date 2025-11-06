import 'dart:async';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  final bool _useSimulation = false;
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

  /// REMOVED FOR PRODUCTION - Simulation can confuse App Store reviewers
  /// Keep this method only in debug builds if needed for testing

  /// Get current location once (for manual check-ins)
  /// Apple-friendly: Only gets location when user explicitly requests it
  Future<LatLng?> getCurrentLocationOnce() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        print('❌ Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return null;
      }

      print('📍 Getting current location (one-time)...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Less aggressive than .best
        timeLimit: const Duration(seconds: 10),
      );

      final location = LatLng(position.latitude, position.longitude);
      print('✅ Got location: ${location.latitude}, ${location.longitude}');
      return location;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Manual check-in: Only saves location when user explicitly requests it
  Future<bool> checkInAtLocation(String circleId, LatLng location) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user for check-in');
      return false;
    }

    try {
      print(
          '📍 Manual check-in at: ${location.latitude}, ${location.longitude}');
      await upsertLocation(circleId, user.id, location, false);
      return true;
    } catch (e) {
      print('❌ Check-in failed: $e');
      return false;
    }
  }

  /// DEPRECATED - Remove for production to avoid Apple rejection
  /// This method will likely cause App Store rejection due to continuous tracking
  @Deprecated(
      'Use getCurrentLocationOnce() and checkInAtLocation() for Apple compliance')
  Future<void> subscribeToLocationUpdates({
    required String circleId,
    required bool useSimulation,
    required Function(LatLng, List<LatLng>) onLocationUpdate,
  }) async {
    // Implementation kept for development/testing only
    // Remove this entire method for production build
    print(
        '⚠️ WARNING: Continuous location tracking should not be used in production');
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

  Future<void> addPost({required PostModel post}) async {
    await _supabase.from('posts').insert(post.toJson());
  }

  /// Get user names for a list of user IDs
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    try {
      final response = await _supabase
          .from('profiles') // or 'users' depending on your table name
          .select('user_id, name')
          .inFilter('user_id', userIds);

      final Map<String, String> userNames = {};
      for (final row in response as List) {
        userNames[row['user_id'] as String] =
            row['name'] as String? ?? 'Unknown User';
      }
      return userNames;
    } catch (e) {
      print('Error fetching user names: $e');
      return {};
    }
  }

  Future<void> subscribeToPost(
      {required String circleId,
      required Function(Map<String, PostModel>) onPostsUpdate}) async {
    final Map<String, PostModel> updated = {};

    final result = _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .listen((rows) {
          print('🎯 Real-time posts update received: ${rows.length} rows');

          for (var row in rows as List) {
            final rowUid = row['id'] as int;
            updated[rowUid.toString()] = PostModel.fromJson(row);
          }
          onPostsUpdate(updated);
        });
    print('SUBSCRIBE POSTS: $result');
  }

  /// Stream other members' locations in real time
  void subscribeToOtherUsersLocations({
    required String circleId,
    required String currentUserId, // Add this parameter to match map_page.dart
    required Function(Map<String, UserLocationInfo>) onLocationsUpdate,
  }) {
    _realtimeSubscription = _supabase
        .from('locations') // 1) subscribe to the table
        .stream(primaryKey: [
          'id'
        ]) // 2) tell it what your PK is (matches DB schema)
        .eq('circle_id', circleId) // 3) apply your filter
        .listen((rows) {
          print('MEOWW');
          print('🎯 Real-time location update received: ${rows.length} rows');
          final Map<String, UserLocationInfo> updated = {};

          for (final row in rows as List) {
            final rowUid = row['user_id'] as String;
            print('  📍 User: $rowUid, Current: $currentUserId');
            if (rowUid == currentUserId) {
              print('  ⏭️ Skipping own location');
              continue; // Skip current user
            }
            final lat = (row['lat'] as num).toDouble();
            final lng = (row['lng'] as num).toDouble();
            updated[rowUid] = UserLocationInfo(
              id: row['id'].toString(),
              userId: row['user_id'],
              location: LatLng(lat, lng),
              lastUpdate: row['updated_at'].toString(),
            );
            print(
                ' ✅ Added location for $rowUid: $lat, $lng, ${row['updated_at']}');
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

  /// REMOVED FOR PRODUCTION - Background tasks are major App Store risk
  /// Apple heavily restricts background location access and may reject apps

  /// Cleanup - Now safe for production without background tasks
  void dispose() {
    _positionStreamSubscription?.cancel();
    _realtimeSubscription?.cancel();
    // No more risky background tasks to clean up
  }
}
