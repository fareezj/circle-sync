import 'package:background_location_tracker/background_location_tracker.dart';
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
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/v4.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

@pragma('vm:entry-point')
void backgroundCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated((data) async {
    print('AWOW LOCATION UPDATE1: ${data.lat} ${data.lon}');

    await Supabase.initialize(
      url: 'https://hnbqegfgzwugkdtfysma.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuYnFlZ2Znend1Z2tkdGZ5c21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTE2NjQsImV4cCI6MjA2MDcyNzY2NH0.l_RqDcUmqvB_MRJ3VG-VQJcjVXqlKeQPghoEy5awTGc',
    );

    // query by db to get below values

    await Supabase.instance.client.from('locations').upsert(
      {
        'circle_id': circleId,
        'user_id': userId,
        'lat': data.lat,
        'lng': data.lon,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_paused': false,
      },
      onConflict:
          'circle_id,user_id', // atomic update/insert :contentReference[oaicite:5]{index=5}
    );
    print('AWOW LOCATION UPDATE: ${data.lat} ${data.lon}');
    print('AWOW PASSED');
  });
}

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
    WidgetsFlutterBinding.ensureInitialized();
    _initPref();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref
          .read(mapNotifierProvider.notifier)
          .updateLocationSharing(_locationService.isLocationSharing);
      ref
          .read(mapNotifierProvider.notifier)
          .loadInitialCircle()
          .then((circle) async {
        await ref
            .read(mapNotifierProvider.notifier)
            .loadCircleDetails(circle, _mapController);
      });

      //ref.read(mapNotifierProvider.notifier).startForegroundTask();
      await BackgroundLocationTrackerManager.initialize(
        backgroundCallback,
        config: const BackgroundLocationTrackerConfig(
          loggingEnabled: true,
          androidConfig: AndroidConfig(
            notificationIcon: 'explore',
            trackingInterval: Duration(seconds: 4),
            distanceFilterMeters: null,
          ),
          iOSConfig: IOSConfig(
            activityType: ActivityType.FITNESS,
            distanceFilterMeters: null,
            restartAfterKill: true,
          ),
        ),
      );
      await BackgroundLocationTrackerManager.startTracking();
    });
  }

  Future<void> _initPref() async {}

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
    final mapState = ref.watch(mapNotifierProvider);

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
                                                    .read(mapNotifierProvider
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
                                                    .read(mapNotifierProvider
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
                                                    .read(mapNotifierProvider
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
