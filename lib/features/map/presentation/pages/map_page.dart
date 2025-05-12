import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/add_circle_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/add_place_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/places_bottom_sheet.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/screens/widgets/circle_bottom_sheet.dart';
import 'package:circle_sync/utils/app_colors.dart';
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
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final DraggableScrollableController _scrollableController =
      DraggableScrollableController();
  final PageController _pageController = PageController();

  int _selectedFeatureIndex = 0; // 0: Info, 1: Members, 2: Places/Add

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
            .loadCircleDetails(circle, _mapController);
      });
      ref.read(mapNotiferProvider.notifier).startForegroundTask();
    });
  }

  Future<void> loadNewCircle(CircleModel circle) async {
    await ref
        .read(mapNotiferProvider.notifier)
        .loadCircleDetails(circle, _mapController);
    await ref.read(mapNotiferProvider.notifier).getPlaces(circle.id);
  }

  void _recenterMap() {
    final loc = ref.read(mapNotiferProvider).currentLocation;
    if (loc != null) _mapController.move(loc, 13.0);
  }

  void _showAddCircleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const AddCircleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotiferProvider);

    return Scaffold(
      body: mapState.currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.topCenter,
              children: [
                MapWidget(
                  mapController: _mapController,
                  members: mapState.circleMembers,
                  mapState: MapState(
                    currentLocation: mapState.currentLocation,
                    osrmRoutePoints: mapState.osrmRoutePoints,
                    trackingPoints: mapState.trackingPoints,
                    otherUsersLocations: mapState.otherUsersLocations,
                  ),
                  hasCircle: mapState.hasCircle,
                  selectedPlace: mapState.selectedPlace,
                  onCurrentLocationTap: () {
                    showCurrentUserInfoDialog(
                        context, mapState.currentLocation!);
                  },
                  onOtherUserTap: (userId, loc) {
                    showUserInfoDialog(context, userId, loc);
                  },
                  places: mapState.placeList,
                  //showPlaceTooltip: true,
                ),
                SafeArea(
                  child: CircleInfoCard(
                    circleList: mapState.joinedCircles,
                    hasCircle: mapState.hasCircle,
                    circleName: mapState.circleName,
                    onCircleTap: (c) {
                      loadNewCircle(c);
                      _recenterMap();
                    },
                    onCreateCircle: () {},
                  ),
                ),
                // draggable & scrollable sheet
                DraggableScrollableSheet(
                  controller: _scrollableController,
                  initialChildSize: 0.35,
                  minChildSize: 0.35,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ElevatedButton(
                        //   onPressed: _showAddCircleSheet,
                        //   child: const Icon(Icons.add_circle),
                        // ),
                        const SizedBox(height: 10),
                        if (mapState.hasCircle)
                          ElevatedButton(
                            onPressed: _recenterMap,
                            child: const Icon(Icons.center_focus_strong),
                          ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: ListView(
                              controller: scrollController,
                              physics: ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 24.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildTabChip(
                                          icon: Icons.info,
                                          index: 0,
                                          context: context),
                                      _buildTabChip(
                                          icon: Icons.group,
                                          index: 1,
                                          context: context),
                                      _buildTabChip(
                                          icon: Icons.place,
                                          index: 2,
                                          context: context),
                                    ],
                                  ),
                                ),
                                // fixed-height PageView inside the ListView
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (i) => setState(
                                        () => _selectedFeatureIndex = i),
                                    children: [
                                      CircleBottomSheet(
                                        members: mapState.circleMembers,
                                        circle: mapState.joinedCircles
                                            .where((e) =>
                                                e.id ==
                                                mapState.currentCircleId)
                                            .first,
                                        hasCircle: mapState.hasCircle,
                                        onCircleTap: (c) {
                                          loadNewCircle(c);
                                          _recenterMap();
                                        },
                                        onCreateCircle: () {},
                                      ),
                                      MembersBottomSheet(
                                        members: mapState.circleMembers,
                                        circleId: mapState.currentCircleId,
                                        otherUsersLocations:
                                            mapState.otherUsersLocations,
                                        onMemberSelected: (memberId) {
                                          final loc = mapState
                                              .otherUsersLocations[memberId];
                                          if (loc != null) {
                                            _mapController.move(loc, 13.0);
                                          }
                                        },
                                        onMemberAdded: (newId) {},
                                      ),
                                      // either add-place or list-places
                                      _selectedFeatureIndex == 2
                                          ? PlacesBottomSheet(
                                              placeList: mapState.placeList,
                                              onClickAddPlace: () {
                                                setState(() {
                                                  _selectedFeatureIndex = 3;
                                                });
                                                _pageController.jumpToPage(2);
                                              },
                                              onClickPlace: (loc) {
                                                ref
                                                    .read(mapNotiferProvider
                                                        .notifier)
                                                    .updateSelectedPlace(loc);
                                                _mapController.move(loc, 13.0);
                                              },
                                            )
                                          : AddPlaceBottomSheet(
                                              initialCenter:
                                                  mapState.currentLocation!,
                                              onClose: () {
                                                setState(() {
                                                  _selectedFeatureIndex = 2;
                                                });
                                                _pageController.jumpToPage(2);
                                              },
                                              onSave: (location, title) async {
                                                await ref
                                                    .read(mapNotiferProvider
                                                        .notifier)
                                                    .insertPlace(
                                                      PlacesModel(
                                                        geofenceId:
                                                            UuidV4().generate(),
                                                        circleId: mapState
                                                                .currentCircleId ??
                                                            '',
                                                        centerGeography:
                                                            'POINT(${location.latitude.toStringAsFixed(4)} ${location.longitude.toStringAsFixed(4)})',
                                                        radiusM: 500,
                                                        title: title,
                                                        message:
                                                            'You are now at $title vicinity',
                                                      ),
                                                    );
                                                await ref
                                                    .read(mapNotiferProvider
                                                        .notifier)
                                                    .getPlaces(mapState
                                                        .currentCircleId);
                                                setState(() {
                                                  _selectedFeatureIndex = 2;
                                                });
                                                _pageController.jumpToPage(2);
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildTabChip({
    required IconData icon,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = _selectedFeatureIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeatureIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Chip(
        labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        label:
            Icon(icon, color: isSelected ? AppColors.white : AppColors.black),
        backgroundColor: isSelected ? AppColors.primaryBlue : null,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      ),
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    _scrollableController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
