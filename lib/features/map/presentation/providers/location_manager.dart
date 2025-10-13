// Flutter imports
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Local imports
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/services/location_fg.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/services/permissions.dart';

/// Manages location-related operations for the map feature
class LocationManager {
  final Ref ref;
  final LocationService _locationService = LocationService();

  LocationManager(this.ref);

  /// Gets the current location sharing status from secure storage
  Future<bool> getLocationSharingStatus() async {
    try {
      final status = await ref.read(getLocationSharingStatusProvider.future);
      return status == 'true';
    } catch (e) {
      debugPrint('Error getting location sharing status: $e');
      return false;
    }
  }

  /// Updates the location sharing status in secure storage
  Future<void> updateLocationSharing(bool isSharing) async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.writeData(
        'locationSharingStatus',
        isSharing.toString(),
      );
    } catch (e) {
      debugPrint('Error updating location sharing: $e');
    }
  }

  /// Checks if location permission is always allowed
  Future<bool> checkLocationPermission() async {
    try {
      final isGranted = await Permission.locationAlways.status;
      return isGranted == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Starts the foreground location task
  Future<void> startForegroundTask() async {
    try {
      final hasPermissions = await Permissions.requestLocationPermissions();
      if (!hasPermissions) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await Supabase.instance.client.from('circles').select('circle_id');

      final circleIds =
          (response as List).map((r) => r['circle_id'] as String).toList();

      await LocationTask.initForegroundTask();
      await LocationTask.startForegroundTask(
        userId: userId,
        circleIds: circleIds,
      );
    } catch (e) {
      debugPrint('Error starting foreground task: $e');
    }
  }

  /// Stops the foreground location task
  Future<void> stopForegroundTask() async {
    try {
      await LocationTask.stopForegroundTask();
    } catch (e) {
      debugPrint('Error stopping foreground task: $e');
    }
  }

  /// Initializes location tracking for a circle
  Future<void> initLocationTracking({
    required String circleId,
    required Function(LatLng, LatLng?, List<LatLng>) onLocationUpdate,
    required Function(Map<String, LatLng>) onOtherUsersUpdate,
  }) async {
    try {
      await _locationService.initInitialLocationAndRoute(
        onLocationAndRouteUpdate: onLocationUpdate,
      );

      _subscribeToOtherUsersLocations(
        circleId: circleId,
        onLocationsUpdate: onOtherUsersUpdate,
      );
    } catch (e) {
      debugPrint('Error initializing location tracking: $e');
    }
  }

  /// Initializes static location (no tracking)
  Future<void> initStaticLocation({
    required Function(LatLng) onLocationUpdate,
    required Function(List<LatLng>) onTrackingUpdate,
  }) async {
    try {
      await _locationService.initStaticLocation(
        onLocationUpdate: onLocationUpdate,
        onTrackingUpdate: onTrackingUpdate,
      );
    } catch (e) {
      debugPrint('Error initializing static location: $e');
    }
  }

  /// Subscribes to other users' locations in a circle
  void _subscribeToOtherUsersLocations({
    required String circleId,
    required Function(Map<String, LatLng>) onLocationsUpdate,
  }) {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      _locationService.subscribeToOtherUsersLocations(
        circleId: circleId,
        currentUserId: currentUserId,
        onLocationsUpdate: onLocationsUpdate,
      );
    } catch (e) {
      debugPrint('Error subscribing to other users locations: $e');
    }
  }

  /// Upserts user location to the database
  Future<void> upsertLocation(
    String circleId,
    String userId,
    LatLng location,
    bool isPaused,
  ) async {
    try {
      await _locationService.upsertLocation(
        circleId,
        userId,
        location,
        isPaused,
      );
    } catch (e) {
      debugPrint('Error upserting location: $e');
    }
  }
}
