import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/widgets/add_place_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/places_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/tab_chip.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/screens/widgets/circle_bottom_sheet.dart';
import 'package:circle_sync/services/geofence_service.dart';
import 'package:circle_sync/services/location_fg.dart';
import 'package:circle_sync/widgets/global_message.dart';
import 'package:circle_sync/widgets/loading_indicator.dart';
import 'package:circle_sync/widgets/message_overlay.dart';
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
    ref
        .read(mapNotifierProvider.notifier)
        .updateLocationSharing(_locationService.isLocationSharing);
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
                DraggableScrollableSheet(
                  controller: _scrollableController,
                  initialChildSize: 0.35,
                  minChildSize: 0.35,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 10),
                        if (mapState.hasCircle)
                          ElevatedButton(
                            onPressed: _recenterMap,
                            child: const Icon(Icons.center_focus_strong),
                          ),
                        ElevatedButton(
                          onPressed: () => _toggleLiveLocation(),
                          child: const Icon(Icons.play_arrow),
                        ),
                        ElevatedButton(
                          onPressed: () async =>
                              LocationTask.stopForegroundTask(),
                          child: const Icon(Icons.stop_circle),
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
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
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
                                                    .updateSelectedChipItem(3);
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
                                                ref
                                                    .read(mapNotifierProvider
                                                        .notifier)
                                                    .updateSelectedChipItem(2);
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
                                                ref
                                                    .read(mapNotifierProvider
                                                        .notifier)
                                                    .updateSelectedChipItem(2);
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

// Future<void> _initPref() async {
//   // 1) get your userId however you need it
//   final userId = await ref.watch(getUserIdProvider.future);

//   // 2) init the plugin
//   await NativeGeofenceManager.instance.initialize();

//   // 3) hard-coded list of your zones
//   final zones = <Map<String, dynamic>>[
//     { 'lat': 3.0620, 'lon': 101.6721, 'radius': 500.0,  'title': 'LRT AWAN BESAR' },
//     { 'lat': 3.0619, 'lon': 101.6609, 'radius': 500.0,  'title': 'Muhibbah' },
//     { 'lat': 3.0657, 'lon': 101.6629, 'radius': 500.0,  'title': 'RnR Kinrara' },
//     { 'lat': 3.1510, 'lon': 101.5698, 'radius': 500.0,  'title': 'Luxor Tech' },
//     { 'lat': 3.1393, 'lon': 101.5967, 'radius': 500.0,  'title': 'Driving NKVE' },
//     { 'lat': 3.0650, 'lon': 101.6812, 'radius': 500.0,  'title': 'W City' },
//     { 'lat': 3.0574, 'lon': 101.6788, 'radius': 500.0,  'title': 'BJ Golf' },
//     { 'lat': 3.0586, 'lon': 101.6875, 'radius': 1000.0, 'title': 'Columbia Hospital' },
//     { 'lat': 3.1137, 'lon': 101.5978, 'radius': 500.0,  'title': 'Church' },
//     { 'lat': 3.0566, 'lon': 101.6180, 'radius': 500.0,  'title': 'Sunway' },
//     { 'lat': 3.0582, 'lon': 101.6739, 'radius': 500.0,  'title': 'HERO' },
//     { 'lat': 3.1525, 'lon': 101.5755, 'radius': 500.0,  'title': 'Leaving Luxor' },
//     { 'lat': 3.0688, 'lon': 101.6731, 'radius': 500.0,  'title': 'Merchant' },
//     { 'lat': 3.0697, 'lon': 101.6416, 'radius': 500.0,  'title': 'Kinrara Intersection' },
//     { 'lat': 3.0921, 'lon': 101.6124, 'radius': 500.0,  'title': 'LDP Corner' },
//     { 'lat': 3.1588, 'lon': 101.5997, 'radius': 500.0,  'title': 'ENTERING NKVE' },
//     { 'lat': 3.0628, 'lon': 101.6678, 'radius': 500.0,  'title': 'OUG CONDO' },
//     { 'lat': 3.1106, 'lon': 101.5921, 'radius': 500.0,  'title': 'Glenmarie' },
//     { 'lat': 3.0631, 'lon': 101.6135, 'radius': 500.0,  'title': 'Tol Sunway' },
//     { 'lat': 3.0551, 'lon': 101.6913, 'radius': 500.0,  'title': 'STADIUM' },
//     // …add more here as needed
//   ];

//   // 4) register each one
//   for (var z in zones) {
//     final fence = Geofence(
//       id:   '${z['title']}|$userId',                   // unique per user
//       location: Location(
//         latitude:  z['lat'] as double,
//         longitude: z['lon'] as double,
//       ),
//       radiusMeters: z['radius'] as double,
//       triggers: { GeofenceEvent.enter, GeofenceEvent.exit, GeofenceEvent.dwell },
//       iosSettings: const IosGeofenceSettings(
//         initialTrigger: true,
//       ),
//       androidSettings: const AndroidGeofenceSettings(
//         initialTriggers: { GeofenceEvent.enter, GeofenceEvent.dwell },
//         expiration: Duration(days: 7),
//         loiteringDelay: Duration(minutes: 5),
//         notificationResponsiveness: Duration(minutes: 5),
//       ),
//     );

//     await NativeGeofenceManager.instance.createGeofence(fence, geofenceTriggered);
//   }

//   // 5) verify how many got registered
//   final active = await NativeGeofenceManager.instance.getRegisteredGeofences();
//   print('There are ${active.length} active geofences.');
// }
