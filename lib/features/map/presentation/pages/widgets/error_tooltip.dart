import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_tooltip/super_tooltip.dart';

class ErrorTooltip extends ConsumerStatefulWidget {
  const ErrorTooltip({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ErrorTooltipState();
}

class _ErrorTooltipState extends ConsumerState<ErrorTooltip> {
  final _controller = SuperTooltipController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _controller.showTooltip();
      },
      child: SuperTooltip(
        showBarrier: true,
        controller: _controller,
        content: TextWidgets.mainRegular(
            title:
                "Enable ‘Always Allow’ location permission to keep your circle updated, even if you’ve exited the app."),
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
          ),
          child: Icon(
            Icons.error,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
