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

  Future<CircleModel?> loadInitialCircle() async {
    final circles = await circleUsecase.getJoinedCircles();
    return circles.fold((l) {
      state = state.copyWith(
        isLoading: false,
        hasCircle: false,
        joinedCircles: [],
      );
      return null;
    }, (circles) async {
      ref.read(mapNotifierProvider.notifier).getPlaces(circles[0].id);
      final members = await circleUsecase.getCircleMembers(circles[0].id);
      state = state.copyWith(
        isLoading: false,
        hasCircle: circles.isNotEmpty,
        joinedCircles: circles,
        currentCircleId: circles.isNotEmpty ? circles[0].id : '',
        circleName: circles.isNotEmpty ? circles[0].name : '',
        circleMembers: members.fold(
          (l) => [],
          (members) => members,
        ),
      );
      return circles[0];
      // await loadCircleDetails(circles[0].id);
    });
  }

  Future<void> loadCircleDetails(
      CircleModel? circle, MapController mapController) async {
    if (circle == null) {
      _enterStaticMode();
      return;
    }
    final members = await circleUsecase.getCircleMembers(circle.id);

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
      await _locationService.startForegroundTask();
      await _locationService.initInitialLocationAndRoute(
        onLocationAndRouteUpdate: (current, destination, trackingPoints) async {
          state = state.copyWith(
            currentLocation: current,
            destinationLocation: destination,
            trackingPoints: trackingPoints,
          );
          final routePoints = await _routeService.getRoute(
            current.latitude,
            current.longitude,
            destination.latitude,
            destination.longitude,
          );
          state = state.copyWith(osrmRoutePoints: routePoints);
          mapController.move(current, 13.0);
        },
      );

      subscribeToLocationUpdates();
      subscribeToOtherUsersLocations();
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
