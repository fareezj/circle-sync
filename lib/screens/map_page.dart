import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:circle_sync/screens/widgets/map_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../route_generator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();

  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  List<LatLng> _osrmRoutePoints = [];
  List<LatLng> _trackingPoints = [];
  Map<String, LatLng> _otherUsersLocations = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _locationsSubscription;

  bool _useSimulation = true; // Simulation mode toggle

  @override
  void initState() {
    super.initState();
    _initInitialLocationAndRoute();
    _subscribeToLocationUpdates();
    _subscribeToOtherUsersLocations();
  }

  Stream<Position> _simulatePositionStream() async* {
    double lat = _currentLocation?.latitude ?? 37.7749;
    double lng = _currentLocation?.longitude ?? -122.4194;
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

  Future<Map<String, dynamic>> getRoute(
      double startLat, double startLon, double endLat, double endLon) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load route');
    }
  }

  Future<void> _initInitialLocationAndRoute() async {
    if (!_useSimulation) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng current = LatLng(position.latitude, position.longitude);
      LatLng destination =
          LatLng(position.latitude + 0.01, position.longitude + 0.01);

      setState(() {
        _currentLocation = current;
        _destinationLocation = destination;
        _trackingPoints = [current];
      });
    } else {
      LatLng current = LatLng(37.7749, -122.4194);
      LatLng destination = LatLng(37.7849, -122.4094);
      setState(() {
        _currentLocation = current;
        _destinationLocation = destination;
        _trackingPoints = [current];
      });
    }

    try {
      Map<String, dynamic> routeData = await getRoute(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );
      List<dynamic> coordinates =
          routeData["routes"][0]["geometry"]["coordinates"];
      List<LatLng> routePoints = coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();

      setState(() {
        _osrmRoutePoints = routePoints;
      });
      // Set initial center and zoom only once when the map loads
      mapController.move(_currentLocation!, 13.0);
    } catch (e) {
      debugPrint(e.toString());
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

  void _subscribeToLocationUpdates() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    const String circleId = 'default_circle';

    if (_useSimulation) {
      _positionStreamSubscription =
          _simulatePositionStream().listen((Position position) async {
        LatLng updatedLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = updatedLocation;
          _trackingPoints.add(updatedLocation);
        });

        await updateUserLocation(circleId, currentUserId,
            updatedLocation.latitude, updatedLocation.longitude);

        if (_destinationLocation != null) {
          try {
            Map<String, dynamic> routeData = await getRoute(
              updatedLocation.latitude,
              updatedLocation.longitude,
              _destinationLocation!.latitude,
              _destinationLocation!.longitude,
            );
            List<dynamic> coordinates =
                routeData["routes"][0]["geometry"]["coordinates"];
            List<LatLng> updatedRoute = coordinates
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();
            setState(() {
              _osrmRoutePoints = updatedRoute;
            });
            // Removed mapController.move() to prevent auto-zoom/re-center
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      });
    } else {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 100,
      );
      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) async {
        LatLng updatedLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = updatedLocation;
          _trackingPoints.add(updatedLocation);
        });

        await updateUserLocation(circleId, currentUserId,
            updatedLocation.latitude, updatedLocation.longitude);

        if (_destinationLocation != null) {
          try {
            Map<String, dynamic> routeData = await getRoute(
              updatedLocation.latitude,
              updatedLocation.longitude,
              _destinationLocation!.latitude,
              _destinationLocation!.longitude,
            );
            List<dynamic> coordinates =
                routeData["routes"][0]["geometry"]["coordinates"];
            List<LatLng> updatedRoute = coordinates
                .map((coord) => LatLng(coord[1] as double, coord[0] as double))
                .toList();
            setState(() {
              _osrmRoutePoints = updatedRoute;
            });
            // Removed mapController.move() to prevent auto-zoom/re-center
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      });
    }
  }

  void _subscribeToOtherUsersLocations() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    const String circleId = 'default_circle';

    _locationsSubscription = getCircleLocations(circleId).listen((snapshot) {
      final updatedLocations = <String, LatLng>{};

      for (final doc in snapshot.docs) {
        final userId = doc['userId'] as String;
        if (userId == currentUserId) continue;

        final lat = doc['latitude'] as double;
        final lng = doc['longitude'] as double;
        updatedLocations[userId] = LatLng(lat, lng);
      }

      setState(() {
        _otherUsersLocations = updatedLocations;
      });
    });
  }

  // Optional: Add a method to manually re-center the map
  void _recenterMap() {
    if (_currentLocation != null) {
      mapController.move(_currentLocation!, 13.0);
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OSM Route & Tracker')),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: _currentLocation ?? LatLng(0, 0),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.yourapp',
          ),
          if (_osrmRoutePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _osrmRoutePoints,
                  strokeWidth: 4.0,
                  color: Colors.blue,
                ),
              ],
            ),
          if (_trackingPoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _trackingPoints,
                  strokeWidth: 3.0,
                  color: Colors.orange,
                ),
              ],
            ),
          MarkerLayer(
            markers: _otherUsersLocations.entries.map((entry) {
              return Marker(
                point: entry.value,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    showUserInfoDialog(context, entry.key, entry.value);
                  },
                  child: Stack(
                    children: [
                      const Icon(Icons.person_pin_circle,
                          color: Colors.red, size: 40),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          MarkerLayer(
            markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      showCurrentUserInfoDialog(context, _currentLocation!);
                    },
                    child: Stack(
                      children: [
                        const Icon(Icons.my_location,
                            color: Colors.green, size: 30),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_destinationLocation != null)
                Marker(
                  point: _destinationLocation!,
                  child: const Icon(Icons.location_pin,
                      color: Colors.red, size: 30),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _useSimulation = !_useSimulation;
                _positionStreamSubscription?.cancel();
                _subscribeToLocationUpdates();
              });
            },
            tooltip: _useSimulation
                ? 'Switch to Real Location'
                : 'Switch to Simulation',
            child:
                Icon(_useSimulation ? Icons.location_on : Icons.location_off),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _recenterMap,
            tooltip: 'Re-center on Current Location',
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }

  // Keep your existing `_showUserInfoDialog`, `_generateChatId`, `_showCurrentUserInfoDialog` methods unchanged
}
