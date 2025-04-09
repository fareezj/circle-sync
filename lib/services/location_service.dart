import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _receivePortSubscription;
  bool _useSimulation = true;
  bool _isLocationSharing = true; // Track whether location sharing is active

  // Getter to expose the sharing state to MapPage
  bool get isLocationSharing => _isLocationSharing;

  Future<void> initStaticLocation({
    required Function(LatLng) onLocationUpdate,
    required Function(List<LatLng>) onTrackingUpdate,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    LatLng current;
    List<LatLng> trackingPoints;
    if (!_useSimulation) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      current = LatLng(position.latitude, position.longitude);
      trackingPoints = [current];
    } else {
      current = LatLng(37.7749, -122.4194);
      trackingPoints = [current];
    }

    onLocationUpdate(current);
    onTrackingUpdate(trackingPoints);
  }

  Future<void> initInitialLocationAndRoute({
    required Function(LatLng, LatLng, List<LatLng>) onLocationAndRouteUpdate,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    LatLng current;
    LatLng destination;
    if (!_useSimulation) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      current = LatLng(position.latitude, position.longitude);
      destination = LatLng(position.latitude + 0.01, position.longitude + 0.01);
    } else {
      current = LatLng(37.7749, -122.4194);
      destination = LatLng(37.7849, -122.4094);
    }

    onLocationAndRouteUpdate(current, destination, [current]);
  }

  Stream<Position> _simulatePositionStream() async* {
    double lat = 37.7749;
    double lng = -122.4194;
    int step = 0;

    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      step++;
      double angle = step * 0.1;
      double deltaLat = 0.001 * cos(angle);
      double deltaLng = 0.001 * sin(angle);

      lat += deltaLat;
      lng += deltaLng;

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

  Future<void> subscribeToLocationUpdates({
    required String circleId,
    required bool useSimulation,
    required Function(LatLng, List<LatLng>) onLocationUpdate,
    LatLng? destinationLocation,
  }) async {
    _useSimulation = useSimulation;
    _positionStreamSubscription?.cancel();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    if (_useSimulation) {
      _positionStreamSubscription =
          _simulatePositionStream().listen((Position position) async {
        LatLng updatedLocation = LatLng(position.latitude, position.longitude);

        // Always update the map locally
        onLocationUpdate(updatedLocation, [updatedLocation]);

        // Only update Firestore if location sharing is active
        if (_isLocationSharing) {
          await updateUserLocation(circleId, currentUserId,
              updatedLocation.latitude, updatedLocation.longitude, false);
        }
      });
    } else {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );
      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) async {
        LatLng updatedLocation = LatLng(position.latitude, position.longitude);

        // Always update the map locally
        onLocationUpdate(updatedLocation, [updatedLocation]);

        // Only update Firestore if location sharing is active
        if (_isLocationSharing) {
          await updateUserLocation(circleId, currentUserId,
              updatedLocation.latitude, updatedLocation.longitude, false);
        }
      });
    }
  }

  Future<void> updateUserLocation(String circleId, String userId, double lat,
      double lng, bool isPaused) async {
    await FirebaseFirestore.instance
        .collection('circles')
        .doc(circleId)
        .collection('locations')
        .doc(userId)
        .set({
      'userId': userId,
      'latitude': lat,
      'longitude': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
      'isPaused': isPaused, // Indicate whether the user has paused sharing
    });
  }

  Stream<QuerySnapshot> getCircleLocations(String circleId) {
    return FirebaseFirestore.instance
        .collection('circles')
        .doc(circleId)
        .collection('locations')
        .snapshots();
  }

  void subscribeToOtherUsersLocations({
    required String circleId,
    required String currentUserId,
    required Function(Map<String, LatLng>) onLocationsUpdate,
  }) {
    getCircleLocations(circleId).listen((snapshot) {
      final updatedLocations = <String, LatLng>{};

      for (final doc in snapshot.docs) {
        final userId = doc['userId'] as String;
        if (userId == currentUserId) continue;

        final lat = doc['latitude'] as double;
        final lng = doc['longitude'] as double;
        updatedLocations[userId] = LatLng(lat, lng);
      }

      onLocationsUpdate(updatedLocations);
    });
  }

  // Renamed from cancelLocationSharing to pauseLocationSharing for clarity
  void pauseLocationSharing(String circleId, LatLng? lastKnownLocation) async {
    _isLocationSharing = false;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || lastKnownLocation == null) return;

    // Update Firestore with the last known location and set isPaused to true
    await updateUserLocation(circleId, currentUserId,
        lastKnownLocation.latitude, lastKnownLocation.longitude, true);
  }

  void resumeLocationSharing(String circleId, LatLng? lastKnownLocation) async {
    _isLocationSharing = true;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || lastKnownLocation == null) return;

    // Update Firestore with the last known location and set isPaused to false
    await updateUserLocation(circleId, currentUserId,
        lastKnownLocation.latitude, lastKnownLocation.longitude, false);
  }

  Future<void> startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Circle Sync Running',
      notificationText: 'Sharing your location with your circle',
      callback: startForegroundTask,
    );

    final receivePort = FlutterForegroundTask.receivePort;
    if (receivePort != null) {
      _receivePortSubscription = receivePort.listen((data) {
        if (data is Map<String, dynamic>) {
          // Handle foreground task updates if needed
        }
      });
    }
  }

  Future<void> stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _receivePortSubscription?.cancel();
    stopForegroundTask();
  }
}
