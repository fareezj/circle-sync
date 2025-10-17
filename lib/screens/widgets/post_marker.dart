import 'dart:convert';
import 'dart:typed_data';

import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PostMarker extends StatefulWidget {
  final WidgetRef ref;
  final PostModel post;

  const PostMarker({
    super.key,
    required this.ref,
    required this.post,
  });

  @override
  State<PostMarker> createState() => _PostMarkerState();
}

class _PostMarkerState extends State<PostMarker>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _cachedImageBytes;

  @override
  bool get wantKeepAlive => true;

  /// Generate a consistent color for each user based on their user ID
  Color _getUserColor() {
    if (widget.post.userId.isEmpty) {
      return AppColors.blueBorder; // Fallback to default color
    }

    // Generate a hash from the user ID for consistent color assignment
    final hash = widget.post.userId.hashCode;

    // Define a palette of distinct, readable colors
    final colorPalette = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFE91E63), // Pink
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF009688), // Teal
    ];

    // Use modulo to get a consistent index for this user
    final colorIndex = hash.abs() % colorPalette.length;
    return colorPalette[colorIndex];
  }

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(PostMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-decode if the image data actually changed
    if (oldWidget.post.image != widget.post.image) {
      _decodeImage();
    }
  }

  void _decodeImage() {
    if (widget.post.image != null) {
      try {
        _cachedImageBytes = base64Decode(widget.post.image!);
      } catch (e) {
        debugPrint('Error decoding image for post ${widget.post.id}: $e');
        _cachedImageBytes = null;
      }
    } else {
      _cachedImageBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isSelected = widget.ref.watch(mapNotifierProvider).selectedPost;
    print('AWOW SELECTED POST: $isSelected');
    return SizedBox(
      width: 10, // Fixed size regardless of marker dimensions
      height: 10, // Fixed size regardless of marker dimensions
      child: Stack(
        clipBehavior: Clip.none, // Allow popup to extend beyond bounds
        children: [
          // Main marker (always visible)
          Positioned.fill(
            child: CircleAvatar(
                radius: 12, // Fixed radius for consistent size
                backgroundColor: _getUserColor(),
                child:
                    Icon(Icons.bookmark_add_rounded, color: AppColors.white)),
          ),
          // Selected popup (conditional) - positioned above marker
          if (isSelected?.id == widget.post.id && isSelected != null)
            Positioned(
              bottom: 55, // Position above the marker
              left: -50,
              right: -50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidgets.mainBold(
                        title: DateFormat('dd MMM yyyy')
                            .format(widget.post.createdAt),
                        textAlign: TextAlign.start,
                        color: AppColors.textDisabled,
                        fontSize: 10),
                    // Fixed size image preview using cached bytes
                    if (_cachedImageBytes != null)
                      Center(
                        child: RepaintBoundary(
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              image: DecorationImage(
                                image: MemoryImage(_cachedImageBytes!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 12),
                    SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 1,
                                child: TextWidgets.mainBold(
                                    title:
                                        '${widget.post.creatorName ?? "Unknown"} :',
                                    textAlign: TextAlign.start,
                                    fontSize: 10)),
                            Expanded(
                              flex: 2,
                              child: TextWidgets.mainSemiBold(
                                  title: widget.post.name.length > 25
                                      ? '${widget.post.name.substring(0, 25)}...'
                                      : widget.post.name,
                                  textAlign: TextAlign.start,
                                  fontSize: 10),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
