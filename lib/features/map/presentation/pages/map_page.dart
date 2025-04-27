import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/widgets/places_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/map_state_model.dart';
import 'package:circle_sync/screens/widgets/circle_info_card.dart';
import 'package:circle_sync/screens/widgets/create_circle_dialog.dart';
import 'package:circle_sync/screens/widgets/map_widgets.dart';
import 'package:circle_sync/screens/widgets/members_bottom_sheet.dart';
import 'package:circle_sync/services/circle_service.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/services/route_service.dart';
import 'package:circle_sync/screens/widgets/map_info.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapPage extends ConsumerStatefulWidget {
  final String? circleId;
  const MapPage({super.key, this.circleId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
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
  LatLng? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _mapState = MapState();
    _isSharingLocation = _locationService.isLocationSharing;
    _loadInitialCircle();
  }

  Future<void> _loadInitialCircle() async {
    final info = await _circleService.getCircleInfo();
    final joined = info['joinedCircles'] as List<CircleModel>;
    final firstId =
        widget.circleId ?? (joined.isNotEmpty ? joined[0].id : null);
    await _loadCircleDetails(firstId);
    if (firstId != null) {
      await ref.read(mapNotiferProvider.notifier).getPlaces(firstId);
    }
  }

  Future<void> _loadCircleDetails(String? circleId) async {
    if (circleId == null) {
      _enterStaticMode();
      return;
    }

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
        onLocationAndRouteUpdate: (current, destination, trackingPoints) async {
          setState(() {
            _mapState = _mapState.copyWith(
              currentLocation: current,
              destinationLocation: destination,
              trackingPoints: trackingPoints,
            );
          });

          final routePoints = await _routeService.getRoute(
            current.latitude,
            current.longitude,
            destination.latitude,
            destination.longitude,
          );
          setState(() {
            _mapState = _mapState.copyWith(osrmRoutePoints: routePoints);
          });

          mapController.move(current, 13.0);
        },
      );

      _subscribeToLocationUpdates();
      _subscribeToOtherUsersLocations();
    } catch (_) {
      _enterStaticMode();
    }
  }

  Future<void> _enterStaticMode() async {
    setState(() {
      _hasCircle = false;
      _currentCircleId = null;
    });
    await _locationService.initStaticLocation(
      onLocationUpdate: _onStaticLocation,
      onTrackingUpdate: (points) {
        setState(() {
          _mapState = _mapState.copyWith(trackingPoints: points);
        });
      },
    );
    if (_mapState.currentLocation != null) {
      mapController.move(_mapState.currentLocation!, 13.0);
    }
  }

  void _onStaticLocation(LatLng loc) {
    setState(() {
      _mapState = _mapState.copyWith(currentLocation: loc);
    });
  }

  Future<void> _createCircleAndJoin(String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final newId = await _circleService.createCircle(name, []);
      await _loadCircleDetails(newId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create circle')),
      );
    }
  }

  void _subscribeToLocationUpdates() {
    if (_currentCircleId == null) return;
    _locationService.subscribeToLocationUpdates(
      circleId: _currentCircleId!,
      useSimulation: _useSimulation,
      onLocationUpdate: (loc, points) {
        setState(() {
          _mapState = _mapState.copyWith(
            currentLocation: loc,
            trackingPoints: [..._mapState.trackingPoints, ...points],
          );
        });
      },
    );
  }

  void _subscribeToOtherUsersLocations() {
    if (_currentCircleId == null) return;
    _locationService.subscribeToOtherUsersLocations(
      circleId: _currentCircleId!,
      onLocationsUpdate: (others) {
        print('Other location: $others');
        setState(() {
          _mapState = _mapState.copyWith(otherUsersLocations: others);
        });
      },
    );
  }

  void _recenterMap() {
    final loc = _mapState.currentLocation;
    if (loc != null) mapController.move(loc, 13.0);
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MembersBottomSheet(
        members: _circleMembers,
        circleId: _currentCircleId ?? '',
        otherUsersLocations: _mapState.otherUsersLocations,
        onMemberSelected: (memberId) {
          final loc = _mapState.otherUsersLocations[memberId];
          if (loc != null) mapController.move(loc, 13.0);
        },
        onMemberAdded: (newId) {
          setState(() {
            _circleMembers.add(newId);
          });
        },
      ),
    );
  }

  void _showPlacesSheet(List<PlacesModel> placeList) {
    showModalBottomSheet(
      context: context,
      builder: (_) => PlacesBottomSheet(
          placeList: placeList,
          onClickPlace: (loc) {
            Navigator.pop(context);
            setState(() {
              _selectedPlace = loc;
            });
            mapController.move(loc, 13.0);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapPageProvider = ref.watch(mapNotiferProvider);

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
                  selectedPlace: _selectedPlace,
                  onCurrentLocationTap: () {
                    showCurrentUserInfoDialog(
                        context, _mapState.currentLocation!);
                  },
                  onOtherUserTap: (userId, loc) {
                    showUserInfoDialog(context, userId, loc);
                  },
                ),
                CircleInfoCard(
                  hasCircle: _hasCircle,
                  circleName: _circleName,
                  onCreateCircle: () {
                    createCircleDialog(context, _createCircleAndJoin);
                  },
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_hasCircle)
            FloatingActionButton(
              onPressed: _showMembersSheet,
              tooltip: 'View Members',
              child: const Icon(Icons.group),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _showPlacesSheet(mapPageProvider.placeList),
            tooltip: 'Places',
            child: const Icon(Icons.location_city),
          ),
          FloatingActionButton(
            onPressed: () {
              if (_currentCircleId != null) {
                if (_isSharingLocation) {
                  _locationService.pauseLocationSharing(
                      _currentCircleId!, _mapState.currentLocation);
                } else {
                  _locationService.resumeLocationSharing(
                      _currentCircleId!, _mapState.currentLocation);
                }
                setState(() => _isSharingLocation = !_isSharingLocation);
              }
            },
            tooltip: _isSharingLocation ? 'Pause Sharing' : 'Resume Sharing',
            child: Icon(_isSharingLocation ? Icons.gps_off : Icons.gps_fixed),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() => _useSimulation = !_useSimulation);
              _subscribeToLocationUpdates();
            },
            tooltip: _useSimulation ? 'Real Location' : 'Simulation',
            child:
                Icon(_useSimulation ? Icons.location_on : Icons.location_off),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _recenterMap,
            tooltip: 'Recenter',
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
