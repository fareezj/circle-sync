import 'package:circle_sync/models/map_state_model.dart';
import 'package:circle_sync/screens/widgets/circle_info_card.dart';
import 'package:circle_sync/screens/widgets/map_widgets.dart';
import 'package:circle_sync/screens/widgets/members_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:circle_sync/services/circle_service.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/services/route_service.dart';
import 'package:circle_sync/screens/widgets/map_info.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final CircleService _circleService = CircleService();
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();

  late MapState _mapState;
  bool _useSimulation = true;
  String? _currentCircleId;
  bool _hasCircle = false;
  String? _circleName;
  List<String> _circleMembers = [];

  @override
  void initState() {
    super.initState();
    _mapState = MapState();
    _checkForCircle();
  }

  Future<void> _checkForCircle() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final memberships = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('circleMemberships')
          .where('isActive', isEqualTo: true)
          .get();

      if (memberships.docs.isNotEmpty) {
        final circleId = memberships.docs.first.id;
        final circle = await _circleService.getCircle(circleId);
        setState(() {
          _currentCircleId = circleId;
          _hasCircle = true;
          _circleName = circle.name;
          _circleMembers = circle.members;
        });
        await _locationService.startForegroundTask();
        await _locationService.initInitialLocationAndRoute(
          onLocationAndRouteUpdate:
              (current, destination, trackingPoints) async {
            setState(() {
              _mapState = _mapState.copyWith(
                currentLocation: current,
                destinationLocation: destination,
                trackingPoints: trackingPoints,
              );
            });
            if (_mapState.destinationLocation != null) {
              final routePoints = await _routeService.getRoute(
                current.latitude,
                current.longitude,
                destination.latitude,
                destination.longitude,
              );
              setState(() {
                _mapState = _mapState.copyWith(osrmRoutePoints: routePoints);
              });
            }
            mapController.move(current, 13.0);
          },
        );
        _subscribeToLocationUpdates();
        _subscribeToOtherUsersLocations();
      } else {
        setState(() {
          _hasCircle = false;
        });
        await _locationService.initStaticLocation(
          onLocationUpdate: (current) {
            setState(() {
              _mapState = _mapState.copyWith(currentLocation: current);
            });
          },
          onTrackingUpdate: (trackingPoints) {
            setState(() {
              _mapState = _mapState.copyWith(trackingPoints: trackingPoints);
            });
          },
        );
        if (_mapState.currentLocation != null) {
          mapController.move(_mapState.currentLocation!, 13.0);
        }
      }
    } catch (e) {
      debugPrint('Error checking for circle: $e');
      setState(() {
        _hasCircle = false;
      });
      await _locationService.initStaticLocation(
        onLocationUpdate: (current) {
          setState(() {
            _mapState = _mapState.copyWith(currentLocation: current);
          });
        },
        onTrackingUpdate: (trackingPoints) {
          setState(() {
            _mapState = _mapState.copyWith(trackingPoints: trackingPoints);
          });
        },
      );
      if (_mapState.currentLocation != null) {
        mapController.move(_mapState.currentLocation!, 13.0);
      }
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
      await _locationService.startForegroundTask();
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

  void _subscribeToLocationUpdates() {
    if (_currentCircleId == null) return;

    _locationService.subscribeToLocationUpdates(
      circleId: _currentCircleId!,
      useSimulation: _useSimulation,
      onLocationUpdate: (updatedLocation, trackingPoints) async {
        setState(() {
          _mapState = _mapState.copyWith(
            currentLocation: updatedLocation,
            trackingPoints: [..._mapState.trackingPoints, ...trackingPoints],
          );
        });
        if (_mapState.destinationLocation != null) {
          final routePoints = await _routeService.getRoute(
            updatedLocation.latitude,
            updatedLocation.longitude,
            _mapState.destinationLocation!.latitude,
            _mapState.destinationLocation!.longitude,
          );
          setState(() {
            _mapState = _mapState.copyWith(osrmRoutePoints: routePoints);
          });
        }
      },
      destinationLocation: _mapState.destinationLocation,
    );
  }

  void _subscribeToOtherUsersLocations() {
    if (_currentCircleId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _locationService.subscribeToOtherUsersLocations(
      circleId: _currentCircleId!,
      currentUserId: currentUserId,
      onLocationsUpdate: (updatedLocations) {
        setState(() {
          _mapState = _mapState.copyWith(otherUsersLocations: updatedLocations);
        });
      },
    );
  }

  void _recenterMap() {
    if (_mapState.currentLocation != null) {
      mapController.move(_mapState.currentLocation!, 13.0);
    }
  }

  void _showMembersBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MembersBottomSheet(
        members: _circleMembers,
        circleId: _currentCircleId!,
        otherUsersLocations: _mapState.otherUsersLocations,
        onMemberSelected: (memberId) {
          final memberLocation = _mapState.otherUsersLocations[memberId];
          if (memberLocation != null) {
            mapController.move(memberLocation, 13.0);
          }
        },
        onMemberAdded: (userId) {
          setState(() {
            _circleMembers.add(userId);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: _mapState.currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MapWidget(
                  mapController: mapController,
                  mapState: _mapState,
                  hasCircle: _hasCircle,
                  onCurrentLocationTap: () {
                    showCurrentUserInfoDialog(
                        context, _mapState.currentLocation!);
                  },
                  onOtherUserTap: (userId, location) {
                    showUserInfoDialog(context, userId, location);
                  },
                ),
                CircleInfoCard(
                  hasCircle: _hasCircle,
                  circleName: _circleName,
                  onCreateCircle: _createCircleAndJoin,
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
}
