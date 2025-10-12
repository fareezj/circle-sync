import 'dart:convert';
import 'dart:typed_data';

import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class PostMarker extends StatefulWidget {
  final PostModel post;
  final bool isSelected;

  const PostMarker({
    super.key,
    required this.post,
    this.isSelected = false,
  });

  @override
  State<PostMarker> createState() => _PostMarkerState();
}

class _PostMarkerState extends State<PostMarker>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _cachedImageBytes;

  @override
  bool get wantKeepAlive => true;

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
    return SizedBox(
      width: 10, // Fixed size regardless of marker dimensions
      height: 10, // Fixed size regardless of marker dimensions
      child: Stack(
        clipBehavior: Clip.none, // Allow popup to extend beyond bounds
        children: [
          // Main marker (always visible)
          Positioned.fill(
            child: CircleAvatar(
              radius: 20, // Fixed radius for consistent size
              backgroundColor: AppColors.blueBorder,
              child: TextWidgets.mainBold(
                color: AppColors.white,
                title: widget.post.name.isNotEmpty
                    ? widget.post.name.substring(0, 1).toUpperCase()
                    : 'P',
                fontSize: 14,
              ),
            ),
          ),
          // Selected popup (conditional) - positioned above marker
          if (widget.isSelected)
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
                  children: [
                    // Truncated text with fixed width
                    SizedBox(
                      width: 108,
                      child: Text(
                        widget.post.name.length > 25
                            ? '${widget.post.name.substring(0, 25)}...'
                            : widget.post.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Fixed size image preview using cached bytes
                    if (_cachedImageBytes != null)
                      RepaintBoundary(
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
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
