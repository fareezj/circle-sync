// Flutter imports
import 'package:circle_sync/screens/posts_bottom_sheet.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Third-party package imports
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/v4.dart';

// Local imports - Features
import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/data/models/map_state.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/error_tooltip.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/features/map/presentation/widgets/add_place_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/places_bottom_sheet.dart';
import 'package:circle_sync/features/map/presentation/widgets/tab_chip.dart';

// Local imports - Models
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/map_state_model.dart';

// Local imports - Providers & Services
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
// REMOVED: geofence_service.dart - causes App Store rejection

// Local imports - Screens & Widgets
import 'package:circle_sync/screens/widgets/circle_bottom_sheet.dart';
import 'package:circle_sync/screens/widgets/circle_info_card.dart';
import 'package:circle_sync/screens/widgets/map_info.dart';
import 'package:circle_sync/screens/widgets/map_widgets.dart';
import 'package:circle_sync/screens/widgets/members_bottom_sheet.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/add_post_dialog.dart';
import 'package:circle_sync/widgets/global_message.dart';
import 'package:circle_sync/widgets/loading_indicator.dart';
import 'package:circle_sync/widgets/message_overlay.dart';

class MapPage extends ConsumerStatefulWidget {
  final String? circleId;
  const MapPage({super.key, this.circleId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  final DraggableScrollableController _scrollableController =
      DraggableScrollableController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initCircleDetails();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermission();
    }
  }

  Future<void> checkPermission() async {
    await ref.read(mapNotifierProvider.notifier).checkLocationPermisssion();
  }

  /// Initializes circle details and sets up the map state
  Future<void> initCircleDetails({bool getLatestCircle = true}) async {
    try {
      final notifier = ref.read(mapNotifierProvider.notifier);

      // Get and update location sharing status
      final locationSharingStatus = await notifier.getLocationSharingStatus();
      await notifier.checkLocationPermisssion();
      await notifier.updateLocationSharing(locationSharingStatus);

      // Load circle and related data
      final circle = await notifier.loadInitialCircle(
        getLatestCircle: getLatestCircle,
      );

      if (circle != null) {
        // REMOVED: initGeofence - causes App Store rejection for background location
        await notifier.loadCircleDetails(circle, _mapController);
        //await notifier.getPlaces(circle.id);
      }
    } catch (e) {
      // Handle error appropriately - could show snackbar or log
      debugPrint('Error initializing circle details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);
    final isLoading = ref.watch(baseLoadingNotifier);

    return Scaffold(
      body: mapState.currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : _buildMapContent(mapState, isLoading),
    );
  }

  /// Builds the main content of the map page
  Widget _buildMapContent(MapPageState mapState, bool isLoading) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        _buildMapWidget(mapState),
        _buildDatePicker(),
        if (!mapState.isLocationAlwaysAllowed) _buildErrorTooltip(),
        if (!mapState.hasCircle) _buildCircleInfoCard(mapState),
        if (mapState.hasCircle) _buildDraggableBottomSheet(mapState),
        ..._buildOverlayWidgets(isLoading),
      ],
    );
  }

  /// Builds the main map widget
  Widget _buildMapWidget(MapPageState mapState) {
    return MapWidget(
      mapController: _mapController,
      members: mapState.circleMembers,
      userModel: CircleMembersModel(
        userId: mapState.currentUser?.userId ?? '',
        name: mapState.currentUser?.name ?? '',
        role: mapState.currentUser?.role ?? '',
      ),
      mapState: MapState(
        currentLocation: mapState.currentLocation,
        osrmRoutePoints: mapState.osrmRoutePoints,
        trackingPoints: mapState.trackingPoints,
        otherUsersLocations: mapState.otherUsersLocations,
      ),
      hasCircle: mapState.hasCircle,
      selectedPlace: mapState.selectedPlace,
      onCurrentLocationTap: () => _handleCurrentLocationTap(mapState),
      onOtherUserTap: (userId, loc) => showUserInfoDialog(context, userId, loc),
      places: mapState.placeList,
      posts: mapState.posts,
      onOtherUserTapPost: (postId, post) =>
          showUserInfoDialog(context, postId, LatLng(post.lat, post.lng)),
    );
  }

  Widget _buildDatePicker() {
    final selectedDate = ref.watch(mapNotifierProvider).selectedDate;

    return Positioned(
      top: 70.0,
      child: GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2050),
            helpText: 'Select Date',
            cancelText: 'Close',
            confirmText: 'Choose',
          );
          if (picked != null) {
            ref.read(mapNotifierProvider.notifier).updateSelectedDate(picked);
          }
        },
        child: Container(
          width: 150,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.white, borderRadius: BorderRadius.circular(12)),
          child: TextWidgets.mainRegular(
              title: ref.watch(mapNotifierProvider.notifier).selectedDate),
        ),
      ),
    );
  }

  /// Builds the error tooltip for location permissions
  Widget _buildErrorTooltip() {
    return const Positioned(
      top: 70.0,
      right: 20.0,
      child: ErrorTooltip(),
    );
  }

  /// Builds the circle info card when no circle is selected
  Widget _buildCircleInfoCard(MapPageState mapState) {
    return SafeArea(
      child: CircleInfoCard(
        circleList: mapState.joinedCircles,
        hasCircle: mapState.hasCircle,
        circleName: mapState.circleName,
        onCircleTap: _handleCircleTap,
        onCircleCreated: _handleCircleCreated,
        onJoinedCircle: _handleJoinedCircle,
      ),
    );
  }

  /// Builds the draggable bottom sheet with map controls
  Widget _buildDraggableBottomSheet(MapPageState mapState) {
    return DraggableScrollableSheet(
      controller: _scrollableController,
      initialChildSize: 0.2,
      minChildSize: 0.2,
      maxChildSize: 0.5,
      builder: (context, scrollController) => _buildBottomSheetContent(
        context,
        scrollController,
        mapState,
      ),
    );
  }

  /// Builds the content of the bottom sheet
  Widget _buildBottomSheetContent(
    BuildContext context,
    ScrollController scrollController,
    MapPageState mapState,
  ) {
    return Column(
      children: [
        const SizedBox(height: 10),
        if (mapState.hasCircle) _buildActionButtons(mapState),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ListView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _buildTabChips(mapState),
                _buildPageView(context, mapState),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons (check-in and recenter)
  Widget _buildActionButtons(MapPageState mapState) {
    final pageNotifier = ref.watch(mapNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCheckInButton(pageNotifier, mapState),
          _buildRecenterButton(),
        ],
      ),
    );
  }

  /// Builds the check-in button
  Widget _buildCheckInButton(
    MapNotifier pageNotifier,
    MapPageState mapState,
  ) {
    return ElevatedButton.icon(
      onPressed: () => _handleCheckInPressed(pageNotifier, mapState),
      icon: const Icon(Icons.location_on),
      label: const Text('Check In Here'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Builds the recenter map button
  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: _recenterMap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: AppColors.babyBlueCard,
        ),
        child: const Icon(
          Icons.location_on,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  /// Builds the tab chips for navigation
  Widget _buildTabChips(MapPageState mapState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TabChip(
            pageController: _pageController,
            icon: Icons.info,
            index: 0,
            context: context,
            isSelected: mapState.selectedChipItem == 0,
          ),
          TabChip(
            pageController: _pageController,
            icon: Icons.group,
            index: 1,
            context: context,
            isSelected: mapState.selectedChipItem == 1,
          ),
          TabChip(
            pageController: _pageController,
            icon: Icons.place,
            index: 2,
            context: context,
            isSelected: mapState.selectedChipItem == 2,
          ),
        ],
      ),
    );
  }

  /// Builds the page view with different bottom sheet contents
  Widget _buildPageView(BuildContext context, MapPageState mapState) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) => ref
            .read(mapNotifierProvider.notifier)
            .updateSelectedChipItem(index),
        children: [
          CircleBottomSheet(onCreateCircle: () {}),
          _buildMembersBottomSheet(mapState),
          _buildPostsBottomSheet(mapState),
        ],
      ),
    );
  }

  Widget _buildPostsBottomSheet(MapPageState mapState) {
    final getFilteredPosts =
        ref.watch(mapNotifierProvider.notifier).postsForSelectedDate;
    return PostsBottomSheet(
      ref: ref,
      posts: getFilteredPosts,
      circleId: mapState.currentCircleId,
      onPostSelected: (LatLng location) {
        _mapController.move(location, 13.0);
      },
      onMemberAdded: (newId) {},
    );
  }

  /// Builds the members bottom sheet
  Widget _buildMembersBottomSheet(MapPageState mapState) {
    return MembersBottomSheet(
      members: mapState.circleMembers,
      circleId: mapState.currentCircleId,
      otherUsersLocations: mapState.otherUsersLocations,
      onMemberSelected: (memberId) {
        final location = mapState.otherUsersLocations[memberId];
        if (location != null) {
          _mapController.move(location, 13.0);
        }
      },
      onMemberAdded: (newId) {},
    );
  }

  /// Builds the places view (either list or add form)
  Widget _buildPlacesView(MapPageState mapState) {
    return mapState.selectedChipItem == 2
        ? _buildPlacesBottomSheet(mapState)
        : _buildAddPlaceBottomSheet(mapState);
  }

  /// Builds the places list bottom sheet
  Widget _buildPlacesBottomSheet(MapPageState mapState) {
    return PlacesBottomSheet(
      placeList: mapState.placeList,
      onClickAddPlace: () => _switchToAddPlaceView(),
      onClickPlace: (location) => _handlePlaceSelection(location),
    );
  }

  /// Builds the add place bottom sheet
  Widget _buildAddPlaceBottomSheet(MapPageState mapState) {
    return AddPlaceBottomSheet(
      initialCenter: mapState.currentLocation!,
      onClose: () => _switchToPlacesView(),
      onSave: (location, title) => _handlePlaceSave(location, title, mapState),
    );
  }

  /// Builds overlay widgets (messages and loading)
  List<Widget> _buildOverlayWidgets(bool isLoading) {
    return [
      MessageOverlay(
        messageProvider: globalMessageNotifier,
        messageType: MessageType.info,
      ),
      MessageOverlay(
        messageProvider: errorMessageNotifier,
        messageType: MessageType.failed,
      ),
      if (isLoading) const LoadingIndicator(),
    ];
  }

  // Event Handlers

  void _handleCurrentLocationTap(MapPageState mapState) {
    if (mapState.currentLocation != null) {
      showCurrentUserInfoDialog(context, mapState.currentLocation!);
    }
  }

  void _handleCircleTap(CircleModel circle) {
    loadNewCircle(circle);
    _recenterMap();
  }

  void _handleCircleCreated() {
    initCircleDetails(getLatestCircle: true);
    _recenterMap();
  }

  void _handleJoinedCircle() {
    initCircleDetails(getLatestCircle: true);
    _recenterMap();
  }

  void _handleCheckInPressed(
    MapNotifier pageNotifier,
    MapPageState mapState,
  ) {
    addPostDialog(
      context: context,
      onClickCamera: () => pageNotifier.addPostImage(ImageSource.camera),
      onClickGallery: () => pageNotifier.addPostImage(ImageSource.gallery),
      onCreate: (name, time) => _checkInAtCurrentLocation(
        postName: name,
        postTime: time,
      ),
      chosenImage: mapState.chosenPostImage,
    );
  }

  void _switchToAddPlaceView() {
    ref.read(mapNotifierProvider.notifier).updateSelectedChipItem(3);
    _pageController.jumpToPage(2);
  }

  void _switchToPlacesView() {
    ref.read(mapNotifierProvider.notifier).updateSelectedChipItem(2);
    _pageController.jumpToPage(2);
  }

  void _handlePlaceSelection(LatLng location) {
    ref.read(mapNotifierProvider.notifier).updateSelectedPlace(location);
    _mapController.move(location, 13.0);
  }

  Future<void> _handlePlaceSave(
    LatLng location,
    String title,
    MapPageState mapState,
  ) async {
    await ref.read(mapNotifierProvider.notifier).insertPlace(
          PlacesModel(
            geofenceId: UuidV4().generate(),
            circleId: mapState.currentCircleId,
            centerGeography:
                'POINT(${location.latitude.toStringAsFixed(4)} ${location.longitude.toStringAsFixed(4)})',
            radiusM: 500,
            title: title,
          ),
        );
    //await initGeofence(ref: ref, circleId: mapState.currentCircleId);
    _switchToPlacesView();
  }

  Future<void> loadNewCircle(CircleModel circle) async {
    //await initGeofence(ref: ref, circleId: circle.id);
    await ref
        .read(mapNotifierProvider.notifier)
        .loadCircleDetails(circle, _mapController);
    await ref.read(mapNotifierProvider.notifier).getPlaces(circle.id);
  }

  void _recenterMap() {
    final loc = ref.read(mapNotifierProvider).currentLocation;
    if (loc != null) _mapController.move(loc, 13.0);
  }

  /// Handles check-in at the current location
  Future<void> _checkInAtCurrentLocation({
    required String postName,
    required DateTime postTime,
  }) async {
    try {
      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final location = LatLng(position.latitude, position.longitude);
      final mapState = ref.read(mapNotifierProvider);

      if (mapState.hasCircle) {
        await ref.read(mapNotifierProvider.notifier).checkInAtLocation(
              location: location,
              postName: postName,
              postTime: postTime,
            );

        if (mounted) {
          Navigator.pop(context);
          _showSuccessSnackbar('✅ Checked in successfully!');
        }
      }
    } catch (e) {
      debugPrint('Check-in failed: $e');
      if (mounted) {
        _showErrorSnackbar('❌ Check-in failed: $e');
      }
    }
  }

  /// Shows a success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Shows an error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
