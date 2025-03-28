import 'dart:async';
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _initInitialLocationAndRoute();
    _subscribeToLocationUpdates();
    _subscribeToOtherUsersLocations();
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

  Stream<DocumentSnapshot> getUserLocation(String circleId, String userId) {
    return FirebaseFirestore.instance
        .collection('circles')
        .doc(circleId)
        .collection('locations')
        .doc(userId)
        .snapshots();
  }

  void _subscribeToLocationUpdates() {
    // Get current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // For demo purposes, we'll use a fixed circle ID
    // In a real app, you would get this from the current user's active circle
    const String circleId = 'default_circle';
    
    // Update location every time the user moves 100 meters
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 100, // Update every 100 meters
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

      // Update user location in Firestore
      await updateUserLocation(
        circleId,
        currentUserId,
        updatedLocation.latitude,
        updatedLocation.longitude,
      );
      
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

  void _subscribeToOtherUsersLocations() {
    // Get current user ID
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // For demo purposes, we'll use a fixed circle ID
    // In a real app, you would get this from the current user's active circle
    const String circleId = 'default_circle';

    // Subscribe to all location updates in the circle
    _locationsSubscription = getCircleLocations(circleId).listen((snapshot) {
      final updatedLocations = <String, LatLng>{};
      
      for (final doc in snapshot.docs) {
        final userId = doc['userId'] as String;
        
        // Skip the current user's location
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

  void _showUserInfoDialog(String userId, LatLng location) {
    debugPrint('Showing info dialog for user: $userId at location: $location');
    
    // Fetch user details from Firestore if available
    FirebaseFirestore.instance.collection('users').doc(userId).get().then(
      (userDoc) {
        debugPrint('User document exists: ${userDoc.exists}');
        if (userDoc.exists) {
          debugPrint('User data: ${userDoc.data()}');
        }
        
        String username = 'Unknown User';
        String email = '';
        
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data.containsKey('name')) {
            username = data['name'] as String;
          }
          if (data != null && data.containsKey('email')) {
            email = data['email'] as String;
          }
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('User Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: $username'),
                const SizedBox(height: 8),
                Text('User ID: $userId'),
                const SizedBox(height: 8),
                Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
                Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (currentUserId != null) {
                    final chatRoomId = _generateChatId(currentUserId, userId);
                    
                    // Create an AppUser object as required by the route generator
                    final user = AppUser(
                      id: userId,
                      name: username,
                      email: email,
                    );
                    
                    // Close dialog first
                    Navigator.of(context).pop();
                    
                    // Then navigate to chat using the correct route name from RouteGenerator
                    Navigator.pushNamed(
                      context,
                      RouteGenerator.chatPage,
                      arguments: {
                        'user': user,
                        'chatRoomId': chatRoomId,
                        'otherUserId': userId,
                      },
                    );
                  }
                },
                child: const Text('Chat'),
              ),
            ],
          ),
        );
      },
    ).catchError((error) {
      debugPrint('Error fetching user data: $error');
      
      // Show a simpler dialog if we can't fetch user details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('User Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: $userId'),
              const SizedBox(height: 8),
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  String _generateChatId(String a, String b) {
    final sortedIds = [a, b]..sort();
    return sortedIds.join('_');
  }

  void _showCurrentUserInfoDialog(LatLng location) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    // Fetch current user details from Firestore
    FirebaseFirestore.instance.collection('users').doc(currentUserId).get().then(
      (userDoc) {
        String username = 'Me';
        String email = '';
        
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data.containsKey('name')) {
            username = data['name'] as String;
          }
          if (data != null && data.containsKey('email')) {
            email = data['email'] as String;
          }
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('My Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: $username'),
                const SizedBox(height: 8),
                Text('User ID: $currentUserId'),
                const SizedBox(height: 8),
                Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
                Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
                const SizedBox(height: 16),
                const Text('This is your current location', 
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    ).catchError((error) {
      // Show a simpler dialog if we can't fetch user details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('My Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: $currentUserId'),
              const SizedBox(height: 8),
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
              const Text('This is your current location', 
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
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
          // Other users' locations as markers
          MarkerLayer(
            markers: _otherUsersLocations.entries.map((entry) {
              return Marker(
                point: entry.value,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    _showUserInfoDialog(entry.key, entry.value);
                  },
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.person_pin_circle,
                        color: Colors.red,
                        size: 40,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Markers for current location and destination
          MarkerLayer(
            markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      _showCurrentUserInfoDialog(_currentLocation!);
                    },
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.my_location,
                          color: Colors.green, 
                          size: 30,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 14,
                            ),
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
    );
  }
}
