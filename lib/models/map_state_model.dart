import 'package:latlong2/latlong.dart';

class MapState {
  LatLng? currentLocation;
  LatLng? destinationLocation;
  List<LatLng> osrmRoutePoints;
  List<LatLng> trackingPoints;
  Map<String, LatLng> otherUsersLocations;

  MapState({
    this.currentLocation,
    this.destinationLocation,
    this.osrmRoutePoints = const [],
    this.trackingPoints = const [],
    this.otherUsersLocations = const {},
  });

  MapState copyWith({
    LatLng? currentLocation,
    LatLng? destinationLocation,
    List<LatLng>? osrmRoutePoints,
    List<LatLng>? trackingPoints,
    Map<String, LatLng>? otherUsersLocations,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      osrmRoutePoints: osrmRoutePoints ?? this.osrmRoutePoints,
      trackingPoints: trackingPoints ?? this.trackingPoints,
      otherUsersLocations: otherUsersLocations ?? this.otherUsersLocations,
    );
  }
}
