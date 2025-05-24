import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationSharingSwitch extends ConsumerWidget {
  final bool isSelected;
  final VoidCallback onClick;
  const LocationSharingSwitch(
      {super.key, required this.isSelected, required this.onClick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: isSelected ? AppColors.primaryBlue : AppColors.babyBlueCard),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.location_searching,
                color: isSelected ? AppColors.white : AppColors.primaryBlue,
              ),
            ] else ...[
              Icon(
                Icons.location_disabled,
                color: isSelected ? AppColors.white : AppColors.primaryBlue,
              ),
            ],
            SizedBox(width: 5.0),
            TextWidgets.mainRegular(
              title: 'Location sharing ${isSelected ? 'on' : 'off'}',
              fontSize: 14.0,
              color: isSelected ? AppColors.white : AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
