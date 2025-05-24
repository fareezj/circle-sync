import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/location_sharing_switch.dart';
import 'package:circle_sync/features/map/presentation/widgets/add_place_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/places_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/tab_chip.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/screens/widgets/circle_bottom_sheet.dart';
import 'package:circle_sync/services/geofence_service.dart';
import 'package:circle_sync/services/location_fg.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/global_message.dart';
import 'package:circle_sync/widgets/loading_indicator.dart';
import 'package:circle_sync/widgets/message_overlay.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
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
import 'package:hive/hive.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initGeofence(ref);
      await initCircleDetails();
    });
  }

  Future<void> initCircleDetails({bool getLatestCircle = false}) async {
    final locationSharingStatus =
        await ref.read(mapNotifierProvider.notifier).getLocationSharingStatus();
    await ref
        .read(mapNotifierProvider.notifier)
        .updateLocationSharing(locationSharingStatus);
    await ref
        .read(mapNotifierProvider.notifier)
        .loadInitialCircle(getLatestCircle: getLatestCircle)
        .then((circle) async {
      await ref
          .read(mapNotifierProvider.notifier)
          .loadCircleDetails(circle, _mapController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final selectedChipItem = ref.watch(mapNotifierProvider).selectedChipItem;
    final isLoading = ref.watch(baseLoadingNotifier);

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
                    onCircleCreated: () {
                      initCircleDetails(getLatestCircle: true);
                      _recenterMap();
                    },
                    onJoinedCircle: () {
                      initCircleDetails(getLatestCircle: true);
                      _recenterMap();
                    },
                  ),
                ),
                // draggable & scrollable sheet
                if (mapState.hasCircle)
                  DraggableScrollableSheet(
                    controller: _scrollableController,
                    initialChildSize: 0.2,
                    minChildSize: 0.2,
                    maxChildSize: 1.0,
                    builder: (context, scrollController) {
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          if (mapState.hasCircle)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  LocationSharingSwitch(
                                    isSelected: mapState.isSharingLocation,
                                    onClick: () {
                                      mapState.isSharingLocation
                                          ? ref
                                              .read(
                                                  mapNotifierProvider.notifier)
                                              .stopForegroundTask()
                                          : ref
                                              .read(
                                                  mapNotifierProvider.notifier)
                                              .startForegroundTask();
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () => _recenterMap(),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        color: AppColors.babyBlueCard,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                        TabChip(
                                          pageController: _pageController,
                                          icon: Icons.info,
                                          index: 0,
                                          context: context,
                                          isSelected: selectedChipItem == 0,
                                        ),
                                        TabChip(
                                          pageController: _pageController,
                                          icon: Icons.group,
                                          index: 1,
                                          context: context,
                                          isSelected: selectedChipItem == 1,
                                        ),
                                        TabChip(
                                          pageController: _pageController,
                                          icon: Icons.place,
                                          index: 2,
                                          context: context,
                                          isSelected: selectedChipItem == 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // fixed-height PageView inside the ListView
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.7,
                                    child: PageView(
                                      controller: _pageController,
                                      onPageChanged: (i) => ref
                                          .read(mapNotifierProvider.notifier)
                                          .updateSelectedChipItem(i),
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
                                        selectedChipItem == 2
                                            ? PlacesBottomSheet(
                                                placeList: mapState.placeList,
                                                onClickAddPlace: () {
                                                  ref
                                                      .read(mapNotifierProvider
                                                          .notifier)
                                                      .updateSelectedChipItem(
                                                          3);
                                                  _pageController.jumpToPage(2);
                                                },
                                                onClickPlace: (loc) {
                                                  ref
                                                      .read(mapNotifierProvider
                                                          .notifier)
                                                      .updateSelectedPlace(loc);
                                                  _mapController.move(
                                                      loc, 13.0);
                                                },
                                              )
                                            : AddPlaceBottomSheet(
                                                initialCenter:
                                                    mapState.currentLocation!,
                                                onClose: () {
                                                  ref
                                                      .read(mapNotifierProvider
                                                          .notifier)
                                                      .updateSelectedChipItem(
                                                          2);
                                                  _pageController.jumpToPage(2);
                                                },
                                                onSave:
                                                    (location, title) async {
                                                  await ref
                                                      .read(mapNotifierProvider
                                                          .notifier)
                                                      .insertPlace(
                                                        PlacesModel(
                                                          geofenceId: UuidV4()
                                                              .generate(),
                                                          circleId: mapState
                                                              .currentCircleId,
                                                          centerGeography:
                                                              'POINT(${location.latitude.toStringAsFixed(4)} ${location.longitude.toStringAsFixed(4)})',
                                                          radiusM: 500,
                                                          title: title,
                                                          message:
                                                              'You are now at $title vicinity',
                                                        ),
                                                      );
                                                  await initGeofence(ref);
                                                  await ref
                                                      .read(mapNotifierProvider
                                                          .notifier)
                                                      .getPlaces(mapState
                                                          .currentCircleId);
                                                  ref
                                                      .read(mapNotifierProvider
                                                          .notifier)
                                                      .updateSelectedChipItem(
                                                          2);
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
                MessageOverlay(
                  messageProvider: globalMessageNotifier,
                  messageType: MessageType.info,
                ),
                MessageOverlay(
                  messageProvider: errorMessageNotifier,
                  messageType: MessageType.failed,
                ),
                if (isLoading) LoadingIndicator()
              ],
            ),
    );
  }

  Future<void> loadNewCircle(CircleModel circle) async {
    await ref
        .read(mapNotifierProvider.notifier)
        .loadCircleDetails(circle, _mapController);
    await ref.read(mapNotifierProvider.notifier).getPlaces(circle.id);
  }

  void _recenterMap() {
    final loc = ref.read(mapNotifierProvider).currentLocation;
    if (loc != null) _mapController.move(loc, 13.0);
  }

  void _toggleLiveLocation() async {
    await ref.read(mapNotifierProvider.notifier).startForegroundTask();
  }
}
