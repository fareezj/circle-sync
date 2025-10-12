import 'dart:convert';
import 'dart:io';

import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/data/models/map_state.dart';
import 'package:circle_sync/features/map/domain/usecases/map_usecase.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/services/location_fg.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/services/permissions.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapNotifier extends StateNotifier<MapPageState> {
  final Ref ref;
  final MapUsecase mapUsecase;
  final LocationService _locationService = LocationService();

  final CircleUsecase circleUsecase;
  MapNotifier(this.mapUsecase, this.circleUsecase, this.ref)
      : super(MapPageState(isLoading: false, placeList: []));

  Future<bool> getLocationSharingStatus() async {
    final status = await ref.read(getLocationSharingStatusProvider.future);
    if (status != null && status.isNotEmpty) {
      return status == 'true';
    }
    return false;
  }

  Future<void> updateLocationSharing(bool isSharing) async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.writeData(
        'locationSharingStatus', isSharing.toString());

    state = state.copyWith(isSharingLocation: isSharing);
  }

  void updateSelectedPlace(LatLng place) {
    state = state.copyWith(selectedPlace: place);
  }

  void updateSelectedMember(CircleMembersModel member) {
    state = state.copyWith(selectedMember: member);
  }

  void updateSelectedPost(PostModel post) {
    state = state.copyWith(selectedPost: post);
  }

  void updateSelectedChipItem(int index) {
    state = state.copyWith(selectedChipItem: index);
  }

  Future<void> stopForegroundTask() async {
    // Update location sharing flag
    updateLocationSharing(false);
    await LocationTask.stopForegroundTask();
  }

  Future<void> startForegroundTask() async {
    // Update location sharing flag
    updateLocationSharing(true);

    bool hasPermissions = await Permissions.requestLocationPermissions();
    if (hasPermissions) {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      try {
        final resp =
            await Supabase.instance.client.from('circles').select('circle_id');

        final circleIds =
            (resp as List).map((r) => r['circle_id'] as String).toList();

        await LocationTask.initForegroundTask();
        await LocationTask.startForegroundTask(
          userId: userId,
          circleIds: circleIds,
        );
      } catch (e) {
        print('error: $e');
      }
    } else {}
  }

  Future<void> checkLocationPermisssion() async {
    final isGranted = await Permission.locationAlways.status;
    state = state.copyWith(
        isLocationAlwaysAllowed: isGranted == PermissionStatus.granted);
  }

  Future<CircleModel?> loadInitialCircle({bool getLatestCircle = false}) async {
    final circles = await circleUsecase.getJoinedCircles();
    final username = await ref.watch(getUsernameProvider.future);
    final userId = await ref.watch(getUserIdProvider.future);

    return circles.fold((l) {
      state = state.copyWith(
        isLoading: false,
        hasCircle: false,
        joinedCircles: [],
      );
      return null;
    }, (circles) async {
      // Load saved current circle
      final savedCircleId = await ref.read(getCurrentCircleId.future);

      CircleModel pointedCircle = getLatestCircle
          ? circles
              .reduce((a, b) => a.dateCreated.isAfter(b.dateCreated) ? a : b)
          : savedCircleId != null
              ? circles.firstWhere((circle) => circle.id == savedCircleId)
              : circles.first;

      // Save selected circle
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.writeData('currentCircleId', pointedCircle.id);

      // Update state with the selected circle
      final members = await circleUsecase.getCircleMembers(pointedCircle.id);

      members.fold((err) {
        print('AWOW MEMBERS: ${err.errorMessage}');
      }, (res) {
        print('AWOW ADD MEMBER: ${res[0].name}');
        state = state.copyWith(circleMembers: res);
      });

      state = state.copyWith(
        isLoading: false,
        hasCircle: true,
        joinedCircles: circles,
        currentCircleId: pointedCircle.id,
        circleName: pointedCircle.name,
        currentUser: CircleMembersModel(
          userId: userId ?? '',
          name: username ?? '',
          role: 'owner',
        ),
      );

      // Load places for the selected circle
      //await ref.read(mapNotifierProvider.notifier).getPlaces(pointedCircle.id);

      return pointedCircle;
    });
  }

  Future<void> loadCircleDetails(
      CircleModel? circle, MapController mapController) async {
    if (circle == null) {
      _enterStaticMode();
      return;
    }

    // Save selected circle
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.writeData('currentCircleId', circle.id);

    //final members = await circleUsecase.getCircleMembers(circle.id);

    // Update state with the new circle details
    state = state.copyWith(
      isLoading: false,
      hasCircle: true,
      currentCircleId: circle.id,
      circleName: circle.name,
    );

    try {
      // PAUSE LIVE LOCATION
      // await _locationService.startForegroundTask();
      await _locationService.initInitialLocationAndRoute(
        onLocationAndRouteUpdate: (current, destination, trackingPoints) async {
          state = state.copyWith(
            currentLocation: current,
            destinationLocation: destination,
            trackingPoints: trackingPoints,
          );
          // final routePoints = await _routeService.getRoute(
          //   current.latitude,
          //   current.longitude,
          //   destination.latitude,
          //   destination.longitude,
          // );
          //state = state.copyWith(osrmRoutePoints: routePoints);
          mapController.move(current, 13.0);
        },
      );
      // Subscribe to other users' locations (safe for App Store)
      subscribeToOtherUsersLocations();
      subscribeToUserPosts();

      // Note: User location updates now happen via manual check-in only
      // This is safer for Apple App Store approval

      // Recenter the map to the new circle's location
      final currentLocation = state.currentLocation;
      if (currentLocation != null) {
        mapController.move(currentLocation, 13.0);
      }
    } catch (_) {
      _enterStaticMode();
    }
  }

  /// REMOVED FOR APP STORE SAFETY
  /// Continuous location tracking replaced with manual check-ins
  /// Use checkInAtLocation() method instead for user-controlled location sharing

  void subscribeToOtherUsersLocations() {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _locationService.subscribeToOtherUsersLocations(
      circleId: state.currentCircleId,
      currentUserId: currentUserId,
      onLocationsUpdate: (others) {
        print('Other users locations now1: $others');
        state = state.copyWith(otherUsersLocations: others);
      },
    );
  }

  void subscribeToUserPosts() {
    print('SUBSCRIBE TO USER POSTS');
    _locationService.subscribeToPost(
        circleId: state.currentCircleId,
        onPostsUpdate: (post) {
          print('READ POST: $post');
          state = state.copyWith(posts: post);
        });
  }

  Future<void> getPlaces(String circleId) async {
    try {
      print('🏞️ Loading places for circle: $circleId');
      final result = await mapUsecase.getPlaces(circleId);
      result.fold((failure) {
        print('❌ Failed to load places: $failure');
        // Don't throw here, just log the failure
        state = state.copyWith(placeList: []);
      }, (list) {
        print(
            '✅ Loaded ${list.length} places: ${list.map((p) => p.title).toList()}');
        state = state.copyWith(placeList: list);
      });
    } catch (e) {
      print('❌ Exception loading places: $e');
      state = state.copyWith(placeList: []);
      // Don't rethrow, just set empty list
    }
  }

  Future<void> insertPlace(PlacesModel place) async {
    try {
      print(place.toJson());
      final result = await mapUsecase.insertPlace(place);
      result.fold((_) {}, (list) {
        print('INSERT SUCCESS!');
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void _onStaticLocation(LatLng loc) {
    state = state.copyWith(currentLocation: loc);
  }

  Future<void> _enterStaticMode() async {
    state = state.copyWith(
      isLoading: false,
      //hasCircle: false,
      //  joinedCircles: [],
      currentCircleId: '',
      circleName: null,
    );
    await _locationService.initStaticLocation(
      onLocationUpdate: _onStaticLocation,
      onTrackingUpdate: (points) {
        state = state.copyWith(trackingPoints: points);
      },
    );
    if (state.currentLocation != null) {
      // mapController.move(state.currentLocation!, 13.0);
    }
  }

  void toggleSimulation(bool useSimulation) {
    print('🎮 Toggling simulation: $useSimulation');
    state = state.copyWith(useSimulation: useSimulation);

    // Note: Simulation removed for App Store safety
    // Location updates now happen only via manual check-ins
  }

  /// Manual check-in at current location
  Future<void> checkInAtLocation({
    required LatLng location,
    required String postName,
    required DateTime postTime,
  }) async {
    print('📍 Manual check-in at: ${location.latitude}, ${location.longitude}');
    if (state.currentCircleId.isEmpty) {
      print('❌ No circle selected for check-in');
      return;
    }

    try {
      print(
          '📍 Manual check-in at: ${location.latitude}, ${location.longitude}');
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ No user authenticated');
        return;
      }

      await _locationService.upsertLocation(
        state.currentCircleId,
        userId,
        location,
        false, // Not paused, this is an active check-in
      );
      String? imageBase64;

      final bytes = await state.chosenPostImage?.readAsBytes();
      if (bytes != null) {
        imageBase64 = base64Encode(bytes);
      }

      await _locationService.addPost(
        post: PostModel(
          circleId: state.currentCircleId,
          userId: userId,
          name: postName,
          image: imageBase64,
          lat: location.latitude,
          lng: location.longitude,
          createdBy: userId,
          createdAt: postTime.toUtc(),
          updatedAt: postTime.toUtc(),
        ),
      );

      // Update current location in state
      state = state.copyWith(currentLocation: location);
      print('✅ Manual check-in successful!');
    } catch (e) {
      print('❌ Error during manual check-in: $e');
    }
  }

  Future<void> addPostImage(ImageSource src) async {
    try {
      ref.read(baseLoadingNotifier.notifier).setLoading(true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: src);
      if (picked != null) {
        state = state.copyWith(chosenPostImage: File(picked.path));
      }
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Content = base64Encode(bytes);
      final fileName = picked.name;
      final fileSize = bytes.length;
      final mimeType =
          lookupMimeType(picked.path) ?? 'application/octet-stream';
    } catch (e) {
      throw Exception(e);
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
