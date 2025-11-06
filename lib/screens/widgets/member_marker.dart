import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/models/user.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MemberMarker extends StatelessWidget {
  final CircleMembersModel user;
  final UserLocationInfo locationInfo;
  final bool isSelected;

  const MemberMarker({
    super.key,
    required this.user,
    required this.locationInfo,
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
                  TextWidgets.mainBold(title: user.name, fontSize: 12),
                  if (locationInfo.lastUpdate != null)
                    Text(
                      'Last update: ${DateFormat('dd/MM HH:mm').format(
                        DateTime.parse(locationInfo.lastUpdate!),
                      )}',
                    )
                ],
              ),
            ),
          ),
        CircleAvatar(
          backgroundColor: AppColors.primaryYellow,
          child: TextWidgets.mainBold(
            title: user.name.substring(0, 2).toUpperCase(),
          ),
        )
      ],
    );
  }
}
