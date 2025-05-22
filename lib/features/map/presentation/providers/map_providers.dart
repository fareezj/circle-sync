import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/data/models/map_state.dart';
import 'package:circle_sync/features/map/domain/usecases/map_usecase.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/services/location_fg.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:circle_sync/services/permissions.dart';
import 'package:circle_sync/services/route_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapNotifier extends StateNotifier<MapPageState> {
  final Ref ref;
  final MapUsecase mapUsecase;
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final CircleUsecase circleUsecase;
  MapNotifier(this.mapUsecase, this.circleUsecase, this.ref)
      : super(MapPageState(isLoading: false, placeList: []));

  void updateLocationSharing(bool isSharing) {
    state = state.copyWith(isSharingLocation: isSharing);
  }

  void updateSelectedPlace(LatLng place) {
    state = state.copyWith(selectedPlace: place);
  }

  void updateSelectedMember(CircleMembersModel member) {
    state = state.copyWith(selectedMember: member);
  }

  void updateSelectedChipItem(int index) {
    state = state.copyWith(selectedChipItem: index);
  }

  Future<void> startForegroundTask() async {
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

  Future<CircleModel?> loadInitialCircle({bool getLatestCircle = false}) async {
    final circles = await circleUsecase.getJoinedCircles();

    return circles.fold((l) {
      state = state.copyWith(
        isLoading: false,
        hasCircle: false,
        joinedCircles: [],
      );
      return null;
    }, (circles) async {
      if (circles.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasCircle: false,
          joinedCircles: [],
          currentCircleId: '',
          circleName: null,
        );
        return null;
      }

      for (var e in circles) {
        print('Raw circles data: ${e.name}');
      }

      CircleModel pointedCircle = getLatestCircle
          ? circles.reduce((a, b) {
              print(
                  'Comparing ${a.name} (${a.dateCreated}) with ${b.name} (${b.dateCreated})');
              return a.dateCreated.isAfter(b.dateCreated) ? a : b;
            })
          : circles.first;

      print(
          'Selected circle: ${pointedCircle.name} (${pointedCircle.dateCreated})');

      // Update state with the selected circle
      final members = await circleUsecase.getCircleMembers(pointedCircle.id);
      state = state.copyWith(
        isLoading: false,
        hasCircle: true,
        joinedCircles: circles,
        currentCircleId: pointedCircle.id,
        circleName: pointedCircle.name,
        circleMembers: members.fold(
          (l) => [],
          (members) => members,
        ),
      );

      // Load places for the selected circle
      await ref.read(mapNotifierProvider.notifier).getPlaces(pointedCircle.id);

      return pointedCircle;
    });
  }

  Future<void> loadCircleDetails(
      CircleModel? circle, MapController mapController) async {
    if (circle == null) {
      _enterStaticMode();
      return;
    }

    final members = await circleUsecase.getCircleMembers(circle.id);

    // Update state with the new circle details
    state = state.copyWith(
      isLoading: false,
      hasCircle: true,
      currentCircleId: circle.id,
      circleName: circle.name,
      circleMembers: members.fold(
        (l) => [],
        (members) => members,
      ),
    );

    try {
      // PAUSE LIVE LOCATION
      // await _locationService.startForegroundTask();
      // await _locationService.initInitialLocationAndRoute(
      //   onLocationAndRouteUpdate: (current, destination, trackingPoints) async {
      //     state = state.copyWith(
      //       currentLocation: current,
      //       destinationLocation: destination,
      //       trackingPoints: trackingPoints,
      //     );
      //     final routePoints = await _routeService.getRoute(
      //       current.latitude,
      //       current.longitude,
      //       destination.latitude,
      //       destination.longitude,
      //     );
      //     state = state.copyWith(osrmRoutePoints: routePoints);
      //     mapController.move(current, 13.0);
      //   },
      // );
      // Subscribe to location updates
      subscribeToLocationUpdates();
      subscribeToOtherUsersLocations();

      // Recenter the map to the new circle's location
      final currentLocation = state.currentLocation;
      if (currentLocation != null) {
        mapController.move(currentLocation, 13.0);
      }
    } catch (_) {
      _enterStaticMode();
    }
  }

  void subscribeToLocationUpdates() {
    _locationService.subscribeToLocationUpdates(
      circleId: state.currentCircleId,
      useSimulation: state.useSimulation,
      onLocationUpdate: (loc, points) {
        print('Location update: $loc');
        print('Points update: $points');
        state = state.copyWith(
          currentLocation: loc,
          osrmRoutePoints: points,
          trackingPoints: [...state.trackingPoints, ...points],
        );
      },
    );
  }

  void subscribeToOtherUsersLocations() {
    _locationService.subscribeToOtherUsersLocations(
      circleId: state.currentCircleId,
      onLocationsUpdate: (others) {
        print('Other users locations now1: $others');
        state = state.copyWith(otherUsersLocations: others);
      },
    );
  }

  Future<void> getPlaces(String circleId) async {
    try {
      final result = await mapUsecase.getPlaces(circleId);
      result.fold((_) {}, (list) {
        state = state.copyWith(placeList: list);
      });
    } catch (e) {
      throw Exception(e);
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
      throw Exception(e);
    }
  }

  void _onStaticLocation(LatLng loc) {
    state = state.copyWith(currentLocation: loc);
  }

  Future<void> _enterStaticMode() async {
    state = state.copyWith(
      isLoading: false,
      hasCircle: false,
      joinedCircles: [],
      currentCircleId: '',
      circleName: null,
      circleMembers: [],
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

  void toggleSimulation(bool toggleSimulation) {}
}

final mapNotifierProvider =
    StateNotifierProvider<MapNotifier, MapPageState>((ref) {
  return MapNotifier(
      ref.watch(mapUsecaseProvider), ref.watch(circleUsecaseProvider), ref);
});
