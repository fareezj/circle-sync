import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class PostMarker extends StatelessWidget {
  final PostModel post;
  final bool isSelected;

  const PostMarker({
    super.key,
    required this.post,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
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
                title: post.name.isNotEmpty
                    ? post.name.substring(0, 1).toUpperCase()
                    : 'P',
                fontSize: 14,
              ),
            ),
          ),
          // Selected popup (conditional) - positioned above marker
          if (isSelected)
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
                        post.name.length > 25
                            ? '${post.name.substring(0, 25)}...'
                            : post.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Fixed size image preview
                    if (post.image != null)
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(post.image!),
                            fit: BoxFit.cover,
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
