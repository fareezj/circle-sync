import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/screens/widgets/member_marker.dart';
import 'package:circle_sync/screens/widgets/place_marker.dart';
import 'package:circle_sync/screens/widgets/post_marker.dart';
import 'package:circle_sync/screens/widgets/user_marker.dart';
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
  final CircleMembersModel userModel;
  final List<CircleMembersModel>? members;
  final VoidCallback onCurrentLocationTap;
  final List<PlacesModel>? places;
  final Map<String, PostModel>? posts;
  final void Function(String userId, LatLng location) onOtherUserTap;
  final void Function(String userId, PostModel post) onOtherUserTapPost;

  const MapWidget({
    super.key,
    this.places,
    this.posts,
    required this.userModel,
    required this.members,
    required this.mapController,
    required this.mapState,
    required this.hasCircle,
    required this.onCurrentLocationTap,
    required this.onOtherUserTap,
    required this.onOtherUserTapPost,
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
          width: 200, // <-- match the child’s max width
          height: 100, // <-- match the child’s max height
          child: GestureDetector(
            onTap: () {
              ref
                  .read(mapNotifierProvider.notifier)
                  .updateSelectedMember(widget.userModel);
            },
            child: UserMarker(
              userName: widget.userModel.name,
              isSelected:
                  ref.read(mapNotifierProvider).selectedMember?.userId ==
                      widget.userModel.userId,
            ),
          ),
        ),
      );
    }

    // Place markers
    if (widget.places != null) {
      print('🗺️ MapWidget received ${widget.places!.length} places');
      for (var place in widget.places!) {
        print(
            '   📍 Place: ${place.title} at ${place.centerGeography} (${place.radiusM}m radius)');
        final latLng = LatLngExtractor.extractLatLng(place.centerGeography);
        print('     → Marker at: ${latLng.latitude}, ${latLng.longitude}');
        markers.add(
          Marker(
            width: 200, // <-- match the child’s max width
            height: 100, // <-- match the child’s max height
            point: LatLng(latLng.latitude, latLng.longitude),
            child: GestureDetector(
              onTap: () {
                ref
                    .read(mapNotifierProvider.notifier)
                    .updateSelectedPlace(latLng);
              },
              child: PlaceMarker(
                place: place,
                isSelected:
                    ref.read(mapNotifierProvider).selectedPlace == latLng,
              ),
            ),
          ),
        );
      }
    }

    // Posts markers
    widget.posts?.forEach((postId, post) {
      print('PLACE POSTS LOCATION: $post');
      markers.add(
        Marker(
          point: LatLng(post.lat, post.lng),
          width: 50, // <-- match the child’s max width
          height: 50, // <-- match the child’s max height
          child: GestureDetector(
            onTap: () {
              ref.read(mapNotifierProvider.notifier).updateSelectedPost(post);
            },
            child: PostMarker(
              post: post,
              isSelected:
                  ref.read(mapNotifierProvider).selectedPost?.id == post.id,
            ),
          ),
        ),
      );
    });

    // Other users' markers
    widget.mapState.otherUsersLocations.forEach((userId, loc) {
      final members = widget.members ?? [];

      // Debug logging
      debugPrint('🔍 Checking userId: $userId at location: $loc');
      debugPrint(
          '📋 Available members: ${members.map((m) => m.userId).toList()}');

      // find all members matching this userId
      final matches = members.where((u) => u.userId == userId);
      if (matches.isEmpty) {
        // no member in the list for this userId → show a generic marker
        debugPrint(
            '❌ No member data for userId: $userId - showing generic marker');
        markers.add(
          Marker(
            point: loc,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => widget.onOtherUserTap(userId, loc),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.orange,
                size: 40,
              ),
            ),
          ),
        );
        return;
      }

      final member = matches.first;
      debugPrint('✅ Found member data for userId: $userId - ${member.name}');
      markers.add(
        Marker(
          point: loc,
          width: 200, // <-- match the child’s max width
          height: 100, // <-- match the child’s max height
          child: GestureDetector(
            onTap: () {
              ref
                  .read(mapNotifierProvider.notifier)
                  .updateSelectedMember(member);
            },
            child: MemberMarker(
              user: member,
              isSelected:
                  ref.read(mapNotifierProvider).selectedMember?.userId ==
                      userId,
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

        // Geofence circles for all places
        if (widget.places != null && widget.places!.isNotEmpty) ...[
          Builder(builder: (context) {
            print(
                '🔵 Creating CircleLayer with ${widget.places!.length} circles');
            for (var place in widget.places!) {
              final latLng =
                  LatLngExtractor.extractLatLng(place.centerGeography);
              print(
                  '   🟦 Circle: ${place.title} at ${latLng.latitude}, ${latLng.longitude} with ${place.radiusM}m radius');
            }
            return const SizedBox.shrink();
          }),
          CircleLayer(
            circles: widget.places!.map((place) {
              final latLng =
                  LatLngExtractor.extractLatLng(place.centerGeography);
              return CircleMarker(
                point: LatLng(latLng.latitude, latLng.longitude),
                radius: place.radiusM, // Use actual radius from DB
                useRadiusInMeter: true,
                color: Colors.purple
                    .withOpacity(0.3), // Purple for better visibility
                borderColor: Colors.purple,
                borderStrokeWidth: 4, // Thick border for visibility
              );
            }).toList(),
          ),
        ],

        // TEST: Always show a test geofence circle to verify rendering works
        CircleLayer(
          circles: [
            CircleMarker(
              point: LatLng(3.1390, 101.6869), // KLCC coordinates
              radius: 500, // 500m radius
              useRadiusInMeter: true,
              color: Colors.red.withOpacity(0.3), // Red for test visibility
              borderColor: Colors.red,
              borderStrokeWidth: 5,
            ),
          ],
        ),

        // Selected place highlight circle
        if (widget.selectedPlace != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.selectedPlace!,
                radius: 1000, // highlight radius
                useRadiusInMeter: true,
                color: Colors.orange.withOpacity(0.2),
                borderColor: Colors.orange,
                borderStrokeWidth: 3,
              ),
            ],
          ),

        // All markers (current user, others, and place pins)
        MarkerLayer(markers: markers),
      ],
    );
  }
}
