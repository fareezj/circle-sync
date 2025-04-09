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
    Function(List<LatLng>)? onRouteUpdate,
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

        onLocationUpdate(updatedLocation, [updatedLocation]);

        await updateUserLocation(circleId, currentUserId,
            updatedLocation.latitude, updatedLocation.longitude);

        if (destinationLocation != null && onRouteUpdate != null) {
          // Route updates will be handled by RouteService
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

        onLocationUpdate(updatedLocation, [updatedLocation]);

        await updateUserLocation(circleId, currentUserId,
            updatedLocation.latitude, updatedLocation.longitude);

        if (destinationLocation != null && onRouteUpdate != null) {
          // Route updates will be handled by RouteService
        }
      });
    }
  }

  Future<void> updateUserLocation(
      String circleId, String userId, double lat, double lng) async {
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
