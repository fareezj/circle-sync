import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initInitialLocationAndRoute();
    _subscribeToLocationUpdates();
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
    // Check location services and permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    // Get initial position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng current = LatLng(position.latitude, position.longitude);
    // For demo: define a destination as a slight offset
    LatLng destination =
        LatLng(position.latitude + 0.01, position.longitude + 0.01);

    // Set initial tracking point
    setState(() {
      _currentLocation = current;
      _destinationLocation = destination;
      _trackingPoints = [current];
    });

    try {
      Map<String, dynamic> routeData = await getRoute(current.latitude,
          current.longitude, destination.latitude, destination.longitude);
      List<dynamic> coordinates =
          routeData["routes"][0]["geometry"]["coordinates"];
      List<LatLng> routePoints = coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();

      setState(() {
        _osrmRoutePoints = routePoints;
      });
      mapController.move(current, 13.0);
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
    // Update location every time the user moves 100 meters
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 100,
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      LatLng updatedLocation = LatLng(position.latitude, position.longitude);
      // Add new location to tracking list if it's different
      setState(() {
        _currentLocation = updatedLocation;
        _trackingPoints.add(updatedLocation);
      });

      // If destination is set, update OSRM route from new current location
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
          // Optionally re-center the map without changing zoom
          mapController.move(updatedLocation, 20);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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
          initialZoom: 20.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.yourapp',
          ),
          // OSRM Route Polyline (blue)
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
          // Tracker Line Polyline (orange) for user's movement
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
          // Markers for current location and destination
          MarkerLayer(
            markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  child: const Icon(Icons.my_location,
                      color: Colors.green, size: 30),
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
    );
  }
}
