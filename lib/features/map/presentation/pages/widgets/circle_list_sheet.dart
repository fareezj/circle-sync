import 'package:circle_sync/features/map/presentation/routers/circle_navigation_router.dart';
import 'package:circle_sync/widgets/confirm_button.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircleListSheet extends ConsumerStatefulWidget {
  final CircleSheetArgs args;

  const CircleListSheet({super.key, required this.args});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CircleListSheetState();
}

class _CircleListSheetState extends ConsumerState<CircleListSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidgets.mainBold(title: 'Your Circles', fontSize: 20.0),
            ],
          ),
          const SizedBox(height: 8),
          // List of circles will be displayed here
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => Divider(),
              itemCount: widget
                  .args.circleList.length, // Replace with actual circle count
              itemBuilder: (context, index) {
                return ListTile(
                  title: TextWidgets.mainSemiBold(
                    title: widget.args.circleList[index].name,
                    textAlign: TextAlign.start,
                  ), // Replace with actual circle name
                  onTap: () {
                    widget.args.onCircleTap(widget.args.circleList[index]);
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: ConfirmButton(
                      onClick: () {
                        circleSheetNavKey.currentState!
                            .pushNamed('/add-circle');
                      },
                      title: 'Create a circle')),
              SizedBox(width: 12),
              Expanded(
                  child: ConfirmButton(
                      onClick: () {
                        circleSheetNavKey.currentState!
                            .pushNamed('/join-circle');
                      },
                      title: 'Join a circle')),
            ],
          )
        ],
      ),
    );
  }
}
