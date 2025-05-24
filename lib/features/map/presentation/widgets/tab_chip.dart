import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabChip extends ConsumerStatefulWidget {
  final IconData icon;
  final int index;
  final BuildContext context;
  final bool isSelected;
  final PageController pageController;
  const TabChip({
    super.key,
    required this.pageController,
    required this.icon,
    required this.index,
    required this.context,
    required this.isSelected,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TabChipState();
}

class _TabChipState extends ConsumerState<TabChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.pageController.animateToPage(
          widget.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: widget.isSelected
              ? AppColors.primaryBlue
              : AppColors.babyBlueCard,
        ),
        child: Icon(
          widget.icon,
          color: widget.isSelected ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }
}
