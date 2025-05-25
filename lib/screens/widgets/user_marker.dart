import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class UserMarker extends StatelessWidget {
  final String userName;
  final bool isSelected;

  const UserMarker({
    super.key,
    required this.userName,
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
              child: TextWidgets.mainBold(title: userName, fontSize: 12),
            ),
          ),
        CircleAvatar(
          backgroundColor: AppColors.blueBorder,
          child: TextWidgets.mainBold(
            color: AppColors.white,
            title: userName.length > 2
                ? userName.substring(0, 2).toUpperCase()
                : 'You',
          ),
        )
      ],
    );
  }
}
