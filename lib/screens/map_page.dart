import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:circle_sync/screens/widgets/map_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:isolate';
import '../models/user.dart';
import '../services/circle_service.dart';
import '../services/location_service.dart';
import '../route_generator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final CircleService _circleService = CircleService();

  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  List<LatLng> _osrmRoutePoints = [];
  List<LatLng> _trackingPoints = [];
  Map<String, LatLng> _otherUsersLocations = {};

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _locationsSubscription;
  StreamSubscription? _receivePortSubscription;

  bool _useSimulation = true;
  String? _currentCircleId;
  bool _hasCircle = false;
  String? _circleName; // Store the circle name
  List<String> _circleMembers = []; // Store the list of member IDs

  @override
  void initState() {
    super.initState();
    _checkForCircle();
  }

  Future<void> _checkForCircle() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      final circleId = userDoc.data()?['currentCircleId'] as String?;

      if (circleId != null) {
        final circle = await _circleService.getCircle(circleId);
        setState(() {
          _currentCircleId = circleId;
          _hasCircle = true;
          _circleName = circle.name;
          _circleMembers = circle.members;
        });
        _startForegroundTask();
        _setupReceivePort();
        _initInitialLocationAndRoute();
        _subscribeToLocationUpdates();
        _subscribeToOtherUsersLocations();
      } else {
        setState(() {
          _hasCircle = false;
        });
        _initStaticLocation();
      }
    } catch (e) {
      debugPrint('Error checking for circle: $e');
      setState(() {
        _hasCircle = false;
      });
      _initStaticLocation();
    }
  }

  Future<void> _createCircleAndJoin() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final circleId = await _circleService.createCircle('My First Circle', []);
      await _circleService.setUserCurrentCircle(currentUserId, circleId);
      final circle = await _circleService.getCircle(circleId);
      setState(() {
        _currentCircleId = circleId;
        _hasCircle = true;
        _circleName = circle.name;
        _circleMembers = circle.members;
      });
      _startForegroundTask();
      _setupReceivePort();
      _subscribeToLocationUpdates();
      _subscribeToOtherUsersLocations();
    } catch (e) {
      debugPrint('Error creating circle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to create circle. Please try again.')),
      );
    }
  }

  void _setupReceivePort() {
    final receivePort = FlutterForegroundTask.receivePort;
    if (receivePort != null) {
      _receivePortSubscription = receivePort.listen((data) {
        if (data is Map<String, dynamic>) {
          setState(() {
            _currentLocation = LatLng(data['latitude'], data['longitude']);
            _trackingPoints.add(_currentLocation!);
          });
        }
      });
    }
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

  Future<void> _initStaticLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    if (!_useSimulation) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng current = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = current;
        _trackingPoints = [current];
      });
    } else {
      LatLng current = LatLng(37.7749, -122.4194);
      setState(() {
        _currentLocation = current;
        _trackingPoints = [current];
      });
    }

    mapController.move(_currentLocation!, 13.0);
  }

  Future<void> _initInitialLocationAndRoute() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    if (!_useSimulation) {
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

  Future<void> _subscribeToLocationUpdates() async {
    if (_currentCircleId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    if (_useSimulation) {
      _positionStreamSubscription =
          _simulatePositionStream().listen((Position position) async {
        LatLng updatedLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = updatedLocation;
          _trackingPoints.add(updatedLocation);
        });

        await updateUserLocation(_currentCircleId!, currentUserId,
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
          } catch (e) {
            debugPrint(e.toString());
          }
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

        setState(() {
          _currentLocation = updatedLocation;
          _trackingPoints.add(updatedLocation);
        });

        await updateUserLocation(_currentCircleId!, currentUserId,
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
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      });
    }
  }

  void _subscribeToOtherUsersLocations() {
    if (_currentCircleId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _locationsSubscription =
        getCircleLocations(_currentCircleId!).listen((snapshot) {
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

  Future<void> _startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Circle Sync Running',
      notificationText: 'Sharing your location with your circle',
      callback: startForegroundTask,
    );
  }

  Future<void> _stopForegroundTask() async {
    await FlutterForegroundTask.stopService();
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      mapController.move(_currentLocation!, 13.0);
    }
  }

  void _showMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Circle Members',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showAddMemberDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _circleMembers.length,
                  itemBuilder: (context, index) {
                    final memberId = _circleMembers[index];
                    return ListTile(
                      title: Text(
                          'User: $memberId'), // Replace with actual user name if available
                      onTap: () {
                        final memberLocation = _otherUsersLocations[memberId];
                        if (memberLocation != null) {
                          mapController.move(memberLocation, 13.0);
                          Navigator.pop(context); // Close the bottom sheet
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Location not available for this member.')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberDialog() {
    final TextEditingController userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member to Circle'),
          content: TextField(
            controller: userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Enter the user ID to add',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final userId = userIdController.text.trim();
                if (userId.isNotEmpty && _currentCircleId != null) {
                  try {
                    await _circleService.addMember(_currentCircleId!, userId);
                    setState(() {
                      _circleMembers.add(userId);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Member added successfully!')),
                    );
                  } catch (e) {
                    debugPrint('Error adding member: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add member.')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _receivePortSubscription?.cancel();
    _stopForegroundTask();
    _positionStreamSubscription?.cancel();
    _locationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? LatLng(0, 0),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.yourapp',
                    ),
                    if (_hasCircle && _osrmRoutePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _osrmRoutePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    if (_hasCircle && _trackingPoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trackingPoints,
                            strokeWidth: 3.0,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    if (_hasCircle)
                      MarkerLayer(
                        markers: _otherUsersLocations.entries.map((entry) {
                          return Marker(
                            point: entry.value,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                showUserInfoDialog(
                                    context, entry.key, entry.value);
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
                                showCurrentUserInfoDialog(
                                    context, _currentLocation!);
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
                        if (_hasCircle && _destinationLocation != null)
                          Marker(
                            point: _destinationLocation!,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 30),
                          ),
                      ],
                    ),
                  ],
                ),
                if (!_hasCircle)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'You need to create a circle to enable location sharing and tracking.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _createCircleAndJoin,
                              child: const Text('Create Circle'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_hasCircle && _circleName != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Card(
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          _circleName!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_hasCircle)
            FloatingActionButton(
              onPressed: _showMembersBottomSheet,
              tooltip: 'View Circle Members',
              child: const Icon(Icons.group),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _useSimulation = !_useSimulation;
                _positionStreamSubscription?.cancel();
                if (_hasCircle) {
                  _subscribeToLocationUpdates();
                }
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
}
