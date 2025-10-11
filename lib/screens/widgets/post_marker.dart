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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          Transform.translate(
            offset: const Offset(0, -10), // Move label upward
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextWidgets.mainBold(title: post.name, fontSize: 12),
                  if (post.image != null) Image.network(post.image!)
                ],
              ),
            ),
          ),
        CircleAvatar(
          backgroundColor: AppColors.blueBorder,
          child: TextWidgets.mainBold(
            color: AppColors.white,
            title: post.name.length > 2
                ? post.name.substring(0, 1).toUpperCase()
                : 'You',
          ),
        )
      ],
    );
  }
}
