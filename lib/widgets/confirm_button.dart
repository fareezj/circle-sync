import 'package:circle_sync/utils/app_colors.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmButton extends ConsumerWidget {
  final VoidCallback onClick;
  final String title;
  final bool isEnabled;
  const ConfirmButton({
    super.key,
    this.isEnabled = true,
    required this.onClick,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => isEnabled
          ? {
              SystemChannels.textInput.invokeMethod('TextInput.hide'),
              onClick(),
            }
          : null,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primaryBlue : AppColors.borderGray,
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        ),
        child: TextWidgets.mainBold(
          title: title,
          color: isEnabled ? AppColors.white : AppColors.darkGray,
          fontSize: 16.0,
        ),
      ),
    );
  }
}
