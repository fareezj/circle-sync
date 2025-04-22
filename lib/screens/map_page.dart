import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/map_state_model.dart';
import 'package:circle_sync/screens/widgets/circle_info_card.dart';
import 'package:circle_sync/screens/widgets/create_circle_dialog.dart';
import 'package:circle_sync/screens/widgets/map_widgets.dart';
import 'package:circle_sync/screens/widgets/members_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:circle_sync/services/circle_service.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/services/route_service.dart';
import 'package:circle_sync/screens/widgets/map_info.dart';

class MapPage extends StatefulWidget {
  final String? circleId;

  const MapPage({super.key, this.circleId});

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
  bool _isSharingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapState = MapState();
    _isSharingLocation = _locationService.isLocationSharing;
    loadCircle();
  }

  Future<void> loadCircle() async {
    Map<String, dynamic> circleList = await _circleService.getCircleInfo();
    var joinedCircles = circleList['joinedCircles'] as List<CircleModel>;
    _loadCircleDetails(widget.circleId ??
        (joinedCircles.isNotEmpty ? joinedCircles[0].id : null));
  }

  Future<void> _loadCircleDetails(String? circleId) async {
    if (circleId != null) {
      try {
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
      } catch (e) {
        debugPrint('Error loading circle: $e');
        setState(() {
          _hasCircle = false;
        });
        await _locationService.initStaticLocation(
          onLocationUpdate: onStaticLocationUpdate, // Use the new callback
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
    } else {
      setState(() {
        _hasCircle = false;
      });
      await _locationService.initStaticLocation(
        onLocationUpdate: onStaticLocationUpdate, // Use the new callback
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

  Future<void> _createCircleAndJoin(String circleName) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final circleId = await _circleService.createCircle(circleName, []);
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
                  onCreateCircle: () {
                    createCircleDialog(
                      context,
                      (String circleName) => _createCircleAndJoin(circleName),
                    );
                  },
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
            tooltip: _isSharingLocation
                ? 'Turn off location sharing'
                : 'Turn on location sharing',
            child: Icon(
                _isSharingLocation ? Icons.gps_off_sharp : Icons.gps_fixed),
            onPressed: () {
              if (_currentCircleId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No circle selected')),
                );
                return;
              }
              if (_isSharingLocation) {
                _locationService.pauseLocationSharing(
                    _currentCircleId!, _mapState.currentLocation);
                setState(() {
                  _isSharingLocation = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location sharing paused')),
                );
              } else {
                _locationService.resumeLocationSharing(
                    _currentCircleId!, _mapState.currentLocation);
                setState(() {
                  _isSharingLocation = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location sharing resumed')),
                );
              }
            },
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

  // Callback for initStaticLocation, which only provides a single LatLng
  void onStaticLocationUpdate(LatLng updatedLocation) {
    setState(() {
      _mapState = _mapState.copyWith(
        currentLocation: updatedLocation,
      );
    });
  }

  // Callback for subscribeToLocationUpdates, which provides LatLng and List<LatLng>
  void onLocationUpdate(LatLng updatedLocation, List<LatLng> trackingPoints) {
    setState(() {
      _mapState = _mapState.copyWith(
        currentLocation: updatedLocation,
        trackingPoints: [..._mapState.trackingPoints, ...trackingPoints],
      );
    });
  }

  void _subscribeToLocationUpdates() {
    print('here2');

    if (_currentCircleId == null) return;

    _locationService.subscribeToLocationUpdates(
      circleId: _currentCircleId!,
      useSimulation: _useSimulation,
      onLocationUpdate: onLocationUpdate,
    );
  }

  void _subscribeToOtherUsersLocations() {
    if (_currentCircleId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _locationService.subscribeToOtherUsersLocations(
      circleId: _currentCircleId!,
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
        circleId: _currentCircleId ?? '',
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
}
