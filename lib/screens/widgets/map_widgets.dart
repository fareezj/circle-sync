// map_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:circle_sync/models/map_state_model.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final MapState mapState;
  final bool hasCircle;
  final LatLng? selectedPlace;
  final VoidCallback onCurrentLocationTap;
  final void Function(String userId, LatLng location) onOtherUserTap;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.mapState,
    required this.hasCircle,
    required this.onCurrentLocationTap,
    required this.onOtherUserTap,
    this.selectedPlace,
  });

  @override
  Widget build(BuildContext context) {
    // 1) build your markers
    final markers = <Marker>[];

    // current user
    if (mapState.currentLocation != null) {
      markers.add(
        Marker(
          point: mapState.currentLocation!,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: onCurrentLocationTap,
            child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
          ),
        ),
      );
    }

    // other users
    mapState.otherUsersLocations.forEach((userId, loc) {
      markers.add(
        Marker(
          point: loc,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => onOtherUserTap(userId, loc),
            child: const Icon(Icons.person_pin_circle,
                color: Colors.redAccent, size: 30),
          ),
        ),
      );
    });

    // selected place pin
    if (selectedPlace != null) {
      markers.add(
        Marker(
          point: selectedPlace!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    // 2) build your polylines
    final polylines = <Polyline>[];
    if (mapState.osrmRoutePoints.isNotEmpty) {
      polylines.add(Polyline(points: mapState.osrmRoutePoints, strokeWidth: 4));
    }
    if (mapState.trackingPoints.isNotEmpty) {
      polylines.add(Polyline(points: mapState.trackingPoints, strokeWidth: 2));
    }

    // 3) assemble the map
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: mapState.currentLocation ?? LatLng(0, 0),
        initialZoom: 13,
      ),
      children: [
        // base tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // draw your route & history
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),

        // **1 km circle under the pin**
        if (selectedPlace != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: selectedPlace!,
                radius: 1000, // in meters
                useRadiusInMeter: true,
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // all markers (current, others, and the place pin)
        MarkerLayer(markers: markers),
      ],
    );
  }
}
