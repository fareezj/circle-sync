import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/add_circle_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/add_place_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/places_bottom_sheet.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:circle_sync/models/map_state_model.dart';
import 'package:circle_sync/screens/widgets/circle_info_card.dart';
import 'package:circle_sync/screens/widgets/map_widgets.dart';
import 'package:circle_sync/screens/widgets/members_bottom_sheet.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/screens/widgets/map_info.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/v4.dart';

class MapPage extends ConsumerStatefulWidget {
  final String? circleId;
  const MapPage({super.key, this.circleId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController mapController = MapController();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(mapNotiferProvider.notifier)
          .updateLocationSharing(_locationService.isLocationSharing);
      ref
          .read(mapNotiferProvider.notifier)
          .loadInitialCircle()
          .then((circle) async {
        await ref
            .read(mapNotiferProvider.notifier)
            .loadCircleDetails(circle, mapController);
      });
    });
  }

  Future<void> loadNewCircle(CircleModel circle) async {
    await ref
        .read(mapNotiferProvider.notifier)
        .loadCircleDetails(circle, mapController);
    await ref.read(mapNotiferProvider.notifier).getPlaces(circle.id);
  }

  // Future<void> _createCircleAndJoin(String name) async {
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;
  //   try {
  //     final newId = await _circleService.createCircle(name);
  //     await _loadCircleDetails(newId);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to create circle')),
  //     );
  //   }
  // }

  void _recenterMap() {
    final loc = ref.read(mapNotiferProvider).currentLocation;
    if (loc != null) mapController.move(loc, 13.0);
  }

  void _showAddCircleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return const AddCircleSheet();
      },
    );
  }

  void _showMembersSheet() {
    final mapPageProvider = ref.watch(mapNotiferProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => MembersBottomSheet(
        members: mapPageProvider.circleMembers,
        circleId: mapPageProvider.currentCircleId,
        otherUsersLocations: mapPageProvider.otherUsersLocations,
        onMemberSelected: (memberId) {
          final loc = mapPageProvider.otherUsersLocations[memberId];
          if (loc != null) mapController.move(loc, 13.0);
        },
        onMemberAdded: (newId) {
          // setState(() {
          //   _circleMembers.add(newId);
          // });
        },
      ),
    );
  }

  void _showPlacesSheet(List<PlacesModel> placeList) {
    final mapPageProvider = ref.watch(mapNotiferProvider);
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          // optional: round the top corners
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          final height = MediaQuery.of(context).size.height * 0.95;
          return SizedBox(
            height: height,
            child: PlacesBottomSheet(
                placeList: placeList,
                onClickAddPlace: () {
                  Navigator.pop(context);
                  _showAddPlaceSheet();
                },
                onClickPlace: (loc) {
                  Navigator.pop(context);
                  ref
                      .read(mapNotiferProvider.notifier)
                      .updateSelectedPlace(loc);
                  mapController.move(loc, 13.0);
                }),
          );
        });
  }

  void _showAddPlaceSheet() {
    final mapPageProvider = ref.watch(mapNotiferProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        // pass in the current center so the map isn’t centered on (0,0)
        final center = mapPageProvider.currentLocation!;
        return AddPlaceBottomSheet(
          initialCenter: center,
          onSave: (location, title) async {
            // 1) call your provider/service to persist
            await ref.read(mapNotiferProvider.notifier).insertPlace(
                  PlacesModel(
                    geofenceId: UuidV4().generate(),
                    circleId: mapPageProvider.currentCircleId ?? '',
                    centerGeography:
                        'POINT(${location.latitude.toStringAsFixed(4)} ${location.longitude.toStringAsFixed(4)})',
                    radiusM: 500,
                    title: title,
                    message: 'You are now at $title vicinity',
                  ),
                );

            // 2) refresh your places
            await ref
                .read(mapNotiferProvider.notifier)
                .getPlaces(mapPageProvider.currentCircleId);

            // 3) close the sheet
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapPageProvider = ref.watch(mapNotiferProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: mapPageProvider.currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MapWidget(
                  mapController: mapController,
                  mapState: MapState(
                    currentLocation:
                        ref.watch(mapNotiferProvider).currentLocation,
                    osrmRoutePoints:
                        ref.watch(mapNotiferProvider).osrmRoutePoints,
                    trackingPoints:
                        ref.watch(mapNotiferProvider).trackingPoints,
                    otherUsersLocations:
                        ref.watch(mapNotiferProvider).otherUsersLocations,
                  ),
                  hasCircle: mapPageProvider.hasCircle,
                  selectedPlace: mapPageProvider.selectedPlace,
                  onCurrentLocationTap: () {
                    showCurrentUserInfoDialog(
                        context, mapPageProvider.currentLocation!);
                  },
                  onOtherUserTap: (userId, loc) {
                    showUserInfoDialog(context, userId, loc);
                  },
                  places: mapPageProvider.placeList,
                ),
                CircleInfoCard(
                  circleList: mapPageProvider.joinedCircles,
                  hasCircle: mapPageProvider.hasCircle,
                  circleName: mapPageProvider.circleName,
                  onCircleTap: (p0) {
                    Navigator.pop(context);
                    loadNewCircle(p0);
                    _recenterMap();
                  },
                  onCreateCircle: () {
                    //createCircleDialog(context, _createCircleAndJoin);
                  },
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddCircleSheet,
            tooltip: 'Add new circle',
            child: const Icon(Icons.add_circle),
          ),
          const SizedBox(height: 10),
          if (mapPageProvider.hasCircle)
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
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showAddPlaceSheet,
            tooltip: 'Add a Place',
            child: const Icon(Icons.add_location_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              final isSharingLocation = mapPageProvider.isSharingLocation;
              if (isSharingLocation) {
                _locationService.pauseLocationSharing(
                    mapPageProvider.currentCircleId,
                    mapPageProvider.currentLocation);
              } else {
                _locationService.resumeLocationSharing(
                    mapPageProvider.currentCircleId,
                    mapPageProvider.currentLocation);
              }
              ref
                  .read(mapNotiferProvider.notifier)
                  .updateLocationSharing(!isSharingLocation);
            },
            tooltip: mapPageProvider.isSharingLocation
                ? 'Pause Sharing'
                : 'Resume Sharing',
            child: Icon(mapPageProvider.isSharingLocation
                ? Icons.gps_off
                : Icons.gps_fixed),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              final toggle = !mapPageProvider.useSimulation;
              ref.read(mapNotiferProvider.notifier).toggleSimulation(toggle);
              ref
                  .read(mapNotiferProvider.notifier)
                  .subscribeToLocationUpdates();
            },
            tooltip:
                mapPageProvider.useSimulation ? 'Real Location' : 'Simulation',
            child: Icon(mapPageProvider.useSimulation
                ? Icons.location_on
                : Icons.location_off),
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
