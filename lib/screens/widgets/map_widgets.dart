// map_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:circle_sync/models/map_state_model.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final MapState mapState;
  final bool hasCircle;
  final VoidCallback onCurrentLocationTap;
  final void Function(String userId, LatLng location) onOtherUserTap;

  const MapWidget({
    required this.mapController,
    required this.mapState,
    required this.hasCircle,
    required this.onCurrentLocationTap,
    required this.onOtherUserTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuild markers anew on every build:
    final markers = <Marker>[];

    // Current user:
    if (mapState.currentLocation != null) {
      markers.add(
        Marker(
          point: mapState.currentLocation!,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: onCurrentLocationTap,
            child: Icon(Icons.my_location, color: Colors.blue, size: 32),
          ),
        ),
      );
    }

    // Other members:
    mapState.otherUsersLocations.forEach((userId, loc) {
      markers.add(
        Marker(
          point: loc,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => onOtherUserTap(userId, loc),
            child: Icon(Icons.person_pin_circle,
                color: Colors.redAccent, size: 30),
          ),
        ),
      );
    });

    // Polylines if any:
    final polylines = <Polyline>[];
    if (mapState.osrmRoutePoints.isNotEmpty) {
      polylines.add(Polyline(
        points: mapState.osrmRoutePoints,
        strokeWidth: 4,
      ));
    }
    if (mapState.trackingPoints.isNotEmpty) {
      polylines.add(Polyline(
        points: mapState.trackingPoints,
        strokeWidth: 2,
      ));
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        // Use `center` not `initialCenter` so mapController.move() works reliably
        initialCenter: mapState.currentLocation ?? LatLng(0, 0),
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          // Switch to the single‐server URL to avoid OSM subdomain warnings
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
