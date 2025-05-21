import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/screens/widgets/member_marker.dart';
import 'package:circle_sync/screens/widgets/place_marker.dart';
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
  final List<CircleMembersModel>? members;
  final VoidCallback onCurrentLocationTap;
  final List<PlacesModel>? places;
  final void Function(String userId, LatLng location) onOtherUserTap;

  const MapWidget({
    super.key,
    this.places,
    required this.members,
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
                    .read(mapNotifierProvider.notifier)
                    .updateSelectedPlace(latLng);
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: PlaceMarker(
                  place: place,
                  isSelected:
                      ref.read(mapNotifierProvider).selectedPlace == latLng,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Other users' markers
    widget.mapState.otherUsersLocations.forEach((userId, loc) {
      final members = widget.members ?? [];

      // find all members matching this userId
      final matches = members.where((u) => u.userId == userId);
      if (matches.isEmpty) {
        // no member in the list for this userId → skip
        debugPrint('No member data for userId: $userId');
        return;
      }

      final member = matches.first;
      markers.add(
        Marker(
          point: loc,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              ref
                  .read(mapNotifierProvider.notifier)
                  .updateSelectedMember(member);
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: MemberMarker(
                user: member,
                isSelected:
                    ref.read(mapNotifierProvider).selectedMember?.userId ==
                        userId,
              ),
            ),
          ),
        ),
      );
    });

    // Selected place marker
    // if (widget.selectedPlace != null) {
    //   markers.add(
    //     Marker(
    //       point: widget.selectedPlace!,
    //       width: 40,
    //       height: 40,
    //       child: const Icon(
    //         Icons.location_pin,
    //         color: Colors.red,
    //         size: 40,
    //       ),
    //     ),
    //   );
    // }
  }

  void _buildPolylines(
      List<LatLng> trackingPoints, List<LatLng> osrmRoutePoints) {
    polylines = <Polyline>[];

    // if (osrmRoutePoints.isNotEmpty) {
    //   setState(() {
    //     polylines.add(
    //       Polyline(
    //         points: osrmRoutePoints,
    //         strokeWidth: 4,
    //         color: Colors.blue,
    //       ),
    //     );
    //   });
    // }
    // if (trackingPoints.isNotEmpty) {
    //   setState(() {
    //     polylines.add(
    //       Polyline(
    //         points: trackingPoints,
    //         strokeWidth: 2,
    //         color: Colors.red,
    //       ),
    //     );
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    _buildMarkers();
    _buildPolylines(ref.watch(mapNotifierProvider).trackingPoints,
        ref.watch(mapNotifierProvider).osrmRoutePoints);
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
        // if (widget.selectedPlace != null)
        //   CircleLayer(
        //     circles: [
        //       CircleMarker(
        //         point: widget.selectedPlace!,
        //         radius: 1000, // in meters
        //         useRadiusInMeter: true,
        //         color: Colors.blue.withOpacity(0.2),
        //         borderColor: Colors.blue,
        //         borderStrokeWidth: 2,
        //       ),
        //     ],
        //   ),

        // All markers (current user, others, and place pins)
        MarkerLayer(markers: markers),
      ],
    );
  }
}
