import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/models/post_model.dart';

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

  // Cache markers to avoid rebuilding on every map movement
  List<Marker>? _cachedMarkers;
  String? _lastMarkersKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  String _createMarkersKey() {
    // Create a key that changes only when marker data actually changes
    final userLoc = widget.mapState.currentLocation?.toString() ?? '';
    final otherUsers = widget.mapState.otherUsersLocations.toString();
    final places = widget.places?.map((p) => p.title).join(',') ?? '';
    final posts = widget.posts?.keys.join(',') ?? '';
    final selectedMember =
        ref.read(mapNotifierProvider).selectedMember?.userId ?? '';
    final selectedPlace =
        ref.read(mapNotifierProvider).selectedPlace?.toString() ?? '';
    final selectedPost = ref.read(mapNotifierProvider).selectedPost?.id ?? '';

    return '$userLoc|$otherUsers|$places|$posts|$selectedMember|$selectedPlace|$selectedPost';
  }

  void _buildMarkers() {
    // Create a key based on the current data state to detect changes
    final currentKey = _createMarkersKey();

    // Use cached markers if data hasn't changed
    if (_cachedMarkers != null && _lastMarkersKey == currentKey) {
      markers = _cachedMarkers!;
      return;
    }

    markers = <Marker>[];

    // Current user marker
    final selectedMemberId =
        ref.read(mapNotifierProvider).selectedMember?.userId;
    if (widget.mapState.currentLocation != null) {
      markers.add(
        Marker(
          key: ValueKey('current_user_${widget.userModel.userId}'),
          point: widget.mapState.currentLocation!,
          width: 200, // <-- match the child's max width
          height: 100, // <-- match the child's max height
          child: GestureDetector(
            onTap: () {
              ref
                  .read(mapNotifierProvider.notifier)
                  .updateSelectedMember(widget.userModel);
            },
            child: UserMarker(
              key: ValueKey('user_marker_${widget.userModel.userId}'),
              userName: widget.userModel.name,
              isSelected: selectedMemberId == widget.userModel.userId,
            ),
          ),
        ),
      );
    }

    // Place markers
    final selectedPlace = ref.read(mapNotifierProvider).selectedPlace;
    if (widget.places != null) {
      print('🗺️ MapWidget received ${widget.places!.length} places');
      for (var place in widget.places!) {
        print(
            '   📍 Place: ${place.title} at ${place.centerGeography} (${place.radiusM}m radius)');
        final latLng = LatLngExtractor.extractLatLng(place.centerGeography);
        print('     → Marker at: ${latLng.latitude}, ${latLng.longitude}');
        markers.add(
          Marker(
            key: ValueKey(
                'place_${place.title}_${latLng.latitude}_${latLng.longitude}'),
            width: 200, // <-- match the child's max width
            height: 100, // <-- match the child's max height
            point: LatLng(latLng.latitude, latLng.longitude),
            child: GestureDetector(
              onTap: () {
                ref
                    .read(mapNotifierProvider.notifier)
                    .updateSelectedPlace(latLng);
              },
              child: PlaceMarker(
                key: ValueKey('place_marker_${place.title}'),
                place: place,
                isSelected: selectedPlace == latLng,
              ),
            ),
          ),
        );
      }
    }

    // Posts markers
    widget.posts?.forEach((postId, post) {
      markers.add(
        Marker(
          key: ValueKey(
              'post_${post.id}'), // Add unique key for stable widget identity
          point: LatLng(post.lat, post.lng),
          width: 50, // <-- match the child's max width
          height: 50, // <-- match the child's max height
          child: GestureDetector(
            onTap: () {
              ref.read(mapNotifierProvider.notifier).updateSelectedPost(post);
            },
            child: PostMarker(
              ref: ref,
              key: ValueKey(
                  'post_marker_${post.id}'), // Add key to PostMarker too
              post: post,
            ),
          ),
        ),
      );
    });

    // Other users' markers
    widget.mapState.otherUsersLocations.forEach((userId, userLocation) {
      final members = widget.members ?? [];

      // Debug logging
      debugPrint('🔍 Checking userId: $userId at location: $userLocation');
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
            point: userLocation.location,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => widget.onOtherUserTap(userId, userLocation.location),
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
          key: ValueKey('member_$userId'),
          point: userLocation.location,
          width: 200, // <-- match the child's max width
          height: 200, // <-- match the child's max height
          child: GestureDetector(
            onTap: () {
              ref
                  .read(mapNotifierProvider.notifier)
                  .updateSelectedMember(member);
            },
            child: MemberMarker(
              key: ValueKey('member_marker_$userId'),
              user: member,
              locationInfo: userLocation,
              isSelected: selectedMemberId == userId,
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

    // Cache the markers and update the key
    _cachedMarkers = List.from(markers);
    _lastMarkersKey = currentKey;
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
        onTap: (tapPosition, point) {
          ref.read(mapNotifierProvider.notifier).updateSelectedPost(null);
          print('✅ Post deselected');
          final isSelected = ref.watch(mapNotifierProvider).selectedPost;
          print('AWOW SELECTED POST: $isSelected');
        },
      ),
      children: [
        // Base tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.wolf.circlesync',
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
