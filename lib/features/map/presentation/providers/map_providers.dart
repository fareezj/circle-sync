// Flutter imports
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Local imports - Features
import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/data/models/map_state.dart';
import 'package:circle_sync/features/map/domain/usecases/map_usecase.dart';

// Local imports - Models
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/post_model.dart';

// Local imports - Providers & Services
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';

// Import new managers
import 'circle_manager.dart';
import 'location_manager.dart';
import 'posts_manager.dart';

/// Main notifier for map-related state management
///
/// This class manages the state and business logic for the map page,
/// including user location, circle management, places, and posts.
/// It delegates specific concerns to specialized manager classes.
class MapNotifier extends StateNotifier<MapPageState> {
  final Ref ref;
  final MapUsecase mapUsecase;
  final CircleUsecase circleUsecase;

  // Managers for different concerns
  late final LocationManager _locationManager;
  late final CircleManager _circleManager;
  late final PostsManager _postsManager;

  MapNotifier(this.mapUsecase, this.circleUsecase, this.ref)
      : super(MapPageState(
            isLoading: false, placeList: [], selectedDate: DateTime.now())) {
    _locationManager = LocationManager(ref);
    _circleManager = CircleManager(ref, circleUsecase);
    _postsManager = PostsManager();
  }

  // Location-related methods
  Future<bool> getLocationSharingStatus() =>
      _locationManager.getLocationSharingStatus();

  Future<void> updateLocationSharing(bool isSharing) async {
    await _locationManager.updateLocationSharing(isSharing);
    state = state.copyWith(isSharingLocation: isSharing);
  }

  Future<void> checkLocationPermisssion() async {
    final isAllowed = await _locationManager.checkLocationPermission();
    state = state.copyWith(isLocationAlwaysAllowed: isAllowed);
  }

  Future<void> startForegroundTask() async {
    updateLocationSharing(true);
    await _locationManager.startForegroundTask();
  }

  Future<void> stopForegroundTask() async {
    updateLocationSharing(false);
    await _locationManager.stopForegroundTask();
  }

  // Circle management methods

  /// Loads the initial circle for the user
  Future<CircleModel?> loadInitialCircle({bool getLatestCircle = false}) async {
    try {
      final circle = await _circleManager.loadInitialCircle(
        getLatestCircle: getLatestCircle,
      );

      if (circle == null) {
        state = state.copyWith(
          isLoading: false,
          hasCircle: false,
          joinedCircles: [],
        );
        return null;
      }

      // Get circle members and current user info
      final members = await _circleManager.getCircleMembers(circle.id);
      final currentUser = await _circleManager.getCurrentUserInfo();

      // Update state with circle information
      state = state.copyWith(
        isLoading: false,
        hasCircle: true,
        selectedCircle: circle,
        currentCircleId: circle.id,
        circleName: circle.name,
        circleMembers: members,
        currentUser: currentUser,
      );

      return circle;
    } catch (e) {
      debugPrint('Error loading initial circle: $e');
      state = state.copyWith(
        isLoading: false,
        hasCircle: false,
        joinedCircles: [],
      );
      return null;
    }
  }

  /// Loads circle details and initializes location tracking
  Future<void> loadCircleDetails(
    CircleModel? circle,
    MapController mapController,
  ) async {
    if (circle == null) {
      await _enterStaticMode();
      return;
    }

    // Update state with circle details
    state = state.copyWith(
      isLoading: false,
      hasCircle: true,
      currentCircleId: circle.id,
      circleName: circle.name,
    );

    try {
      // Initialize location tracking using the location manager
      await _locationManager.initLocationTracking(
        circleId: circle.id,
        onLocationUpdate: (current, destination, trackingPoints) {
          state = state.copyWith(
            currentLocation: current,
            destinationLocation: destination,
            trackingPoints: trackingPoints,
          );
          mapController.move(current, 13.0);
        },
        onOtherUsersUpdate: (otherUsers) {
          state = state.copyWith(otherUsersLocations: otherUsers);
        },
      );

      // Subscribe to posts updates
      _postsManager.subscribeToPostsUpdates(
        circleId: circle.id,
        onPostsUpdate: (posts) {
          state = state.copyWith(posts: posts, originalPosts: posts);
        },
      );
    } catch (e) {
      debugPrint('Error loading circle details: $e');
      await _enterStaticMode();
    }
  }

  // Places management methods

  /// Gets places for a specific circle
  Future<void> getPlaces(String circleId) async {
    try {
      final result = await mapUsecase.getPlaces(circleId);
      result.fold(
        (failure) {
          debugPrint('Failed to load places: ${failure.errorMessage}');
          state = state.copyWith(placeList: []);
        },
        (places) {
          state = state.copyWith(placeList: places);
        },
      );
    } catch (e) {
      debugPrint('Exception loading places: $e');
      state = state.copyWith(placeList: []);
    }
  }

  /// Inserts a new place
  Future<void> insertPlace(PlacesModel place) async {
    try {
      final result = await mapUsecase.insertPlace(place);
      result.fold(
        (failure) {
          throw Exception('Failed to insert place: ${failure.errorMessage}');
        },
        (_) {
          debugPrint('Place inserted successfully');
          // Refresh places list
          getPlaces(place.circleId);
        },
      );
    } catch (e) {
      debugPrint('Error inserting place: $e');
      rethrow;
    }
  }

  // UI state management methods

  String get selectedDate {
    final today = DateTime.now();
    if (DateTime(state.selectedDate.year, state.selectedDate.month,
            state.selectedDate.day) ==
        DateTime(today.year, today.month, today.day)) {
      return 'Today';
    }
    return DateFormat('dd MMM yyyy').format(state.selectedDate);
  }

  /// Returns a map of posts that match the provided [date] (matching day/month/year).
  Map<String, PostModel> getPostsForDate(DateTime date) {
    final filteredEntries = state.originalPosts.entries.where((entry) {
      final createdLocal = entry.value.createdAt;
      return createdLocal.year == date.year &&
          createdLocal.month == date.month &&
          createdLocal.day == date.day;
    });
    return Map<String, PostModel>.fromEntries(filteredEntries);
  }

  /// Convenience getter for posts matching the currently selected date.
  Map<String, PostModel> get postsForSelectedDate =>
      getPostsForDate(state.selectedDate);

  void updateSelectedDate(DateTime dateTime) {
    state = state.copyWith(
        selectedDate: dateTime, posts: getPostsForDate(dateTime));
  }

  void updateSelectedPlace(LatLng place) {
    state = state.copyWith(selectedPlace: place);
  }

  void updateSelectedMember(CircleMembersModel member) {
    state = state.copyWith(selectedMember: member);
  }

  void updateSelectedPost(PostModel? post) {
    state = state.copyWith(selectedPost: post);
  }

  void updateSelectedChipItem(int index) {
    state = state.copyWith(selectedChipItem: index);
  }

  // Helper methods for location and posts

  /// Enters static mode when no circle is available
  Future<void> _enterStaticMode() async {
    state = state.copyWith(
      isLoading: false,
      circleName: null,
    );

    try {
      await _locationManager.initStaticLocation(
        onLocationUpdate: (location) {
          state = state.copyWith(currentLocation: location);
        },
        onTrackingUpdate: (points) {
          state = state.copyWith(trackingPoints: points);
        },
      );
    } catch (e) {
      debugPrint('Error entering static mode: $e');
    }
  }

  /// Toggles simulation mode (for development/testing)
  void toggleSimulation(bool useSimulation) {
    state = state.copyWith(useSimulation: useSimulation);
  }

  /// Handles manual check-in at current location
  Future<void> checkInAtLocation({
    required LatLng location,
    required String postName,
    required DateTime postTime,
  }) async {
    if (state.currentCircleId.isEmpty) {
      debugPrint('No circle selected for check-in');
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('No user authenticated');
        return;
      }

      // Update location in database
      await _locationManager.upsertLocation(
        state.currentCircleId,
        userId,
        location,
        false, // Not paused
      );

      // Create and add post
      final imageBase64 = await _postsManager.convertImageToBase64(
        state.chosenPostImage,
      );

      final post = PostModel(
        circleId: state.currentCircleId,
        userId: userId,
        name: postName,
        image: imageBase64,
        lat: location.latitude,
        lng: location.longitude,
        createdBy: userId,
        createdAt: postTime.toUtc(),
        updatedAt: postTime.toUtc(),
      );

      await _postsManager.addPost(post);

      // Update current location in state
      state = state.copyWith(currentLocation: location);
      debugPrint('Manual check-in successful');
    } catch (e) {
      debugPrint('Error during manual check-in: $e');
      rethrow;
    }
  }

  /// Handles post image selection and processing
  Future<void> addPostImage(ImageSource source) async {
    try {
      ref.read(baseLoadingNotifier.notifier).setLoading(true);

      final imageFile = await _postsManager.processImageForPost(source);
      if (imageFile != null) {
        state = state.copyWith(chosenPostImage: imageFile);
      }
    } catch (e) {
      debugPrint('Error adding post image: $e');
      rethrow;
    } finally {
      ref.read(baseLoadingNotifier.notifier).setLoading(false);
    }
  }
}

final mapNotifierProvider =
    StateNotifierProvider<MapNotifier, MapPageState>((ref) {
  return MapNotifier(
      ref.watch(mapUsecaseProvider), ref.watch(circleUsecaseProvider), ref);
});
