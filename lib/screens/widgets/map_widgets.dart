import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/utils/coordinate_extractor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:circle_sync/models/map_state_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapWidget extends ConsumerStatefulWidget {
  final MapController mapController;
  final MapState mapState;
  final bool hasCircle;
  final LatLng? selectedPlace;
  final VoidCallback onCurrentLocationTap;
  final List<PlacesModel>? places;
  final void Function(String userId, LatLng location) onOtherUserTap;

  const MapWidget({
    super.key,
    this.places,
    required this.mapController,
    required this.mapState,
    required this.hasCircle,
    required this.onCurrentLocationTap,
    required this.onOtherUserTap,
    this.selectedPlace,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  late List<Marker> markers;
  late List<Polyline> polylines;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  void _buildMarkers() {
    markers = <Marker>[];

    // Current user marker
    if (widget.mapState.currentLocation != null) {
      markers.add(
        Marker(
          point: widget.mapState.currentLocation!,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: widget.onCurrentLocationTap,
            child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
          ),
        ),
      );
    }

    // Place markers
    if (widget.places != null) {
      for (var place in widget.places!) {
        final latLng = LatLngExtractor.extractLatLng(place.centerGeography);
        markers.add(
          Marker(
            point: LatLng(latLng.latitude, latLng.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                ref
                    .read(mapNotiferProvider.notifier)
                    .updateSelectedPlace(latLng);
                widget.mapController.move(latLng, 13.0);

                // Show place details
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Place Details'),
                    content: Text(
                        'You selected a place at ${latLng.latitude}, ${latLng.longitude}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child:
                  const Icon(Icons.location_on, color: Colors.blue, size: 32),
            ),
          ),
        );
      }
    }

    // Other users' markers
    widget.mapState.otherUsersLocations.forEach((userId, loc) {
      print('Other user location: $userId, $loc');
      markers.add(
        Marker(
          point: loc,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => widget.onOtherUserTap(userId, loc),
            child: const Icon(Icons.person_pin_circle,
                color: Colors.redAccent, size: 30),
          ),
        ),
      );
    });

    // Selected place marker
    if (widget.selectedPlace != null) {
      markers.add(
        Marker(
          point: widget.selectedPlace!,
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
  }

  void _buildPolylines(
      List<LatLng> trackingPoints, List<LatLng> osrmRoutePoints) {
    polylines = <Polyline>[];

    if (osrmRoutePoints.isNotEmpty) {
      setState(() {
        polylines.add(
          Polyline(
            points: osrmRoutePoints,
            strokeWidth: 4,
            color: Colors.blue,
          ),
        );
      });
    }
    if (trackingPoints.isNotEmpty) {
      setState(() {
        polylines.add(
          Polyline(
            points: trackingPoints,
            strokeWidth: 2,
            color: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildMarkers();
    _buildPolylines(ref.watch(mapNotiferProvider).trackingPoints,
        ref.watch(mapNotiferProvider).osrmRoutePoints);
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.mapState.currentLocation ?? LatLng(0, 0),
        initialZoom: 13,
      ),
      children: [
        // Base tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Draw routes and tracking history
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),

        // 1 km circle under the selected place pin
        if (widget.selectedPlace != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.selectedPlace!,
                radius: 1000, // in meters
                useRadiusInMeter: true,
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // All markers (current user, others, and place pins)
        MarkerLayer(markers: markers),
      ],
    );
  }
}
