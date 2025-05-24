import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:circle_sync/features/map/presentation/pages/widgets/circle_list_sheet.dart';
import 'package:circle_sync/features/map/presentation/routers/circle_navigation_router.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/widgets/confirm_button.dart';
import 'package:circle_sync/widgets/text_widgets.dart';

class CircleInfoCard extends StatelessWidget {
  final bool hasCircle;
  final String? circleName;
  final List<CircleModel> circleList;
  final Function(CircleModel) onCircleTap;
  final VoidCallback onCircleCreated;
  final VoidCallback onJoinedCircle;

  const CircleInfoCard({
    super.key,
    required this.onCircleTap,
    required this.circleList,
    required this.hasCircle,
    required this.circleName,
    required this.onCircleCreated,
    required this.onJoinedCircle,
  });

  void onShowCircleModal({
    required BuildContext context,
    String? initialRoute,
    bool onShowBack = true,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext modalContext) {
        return CircleNavigationRouter(
          initialRoute: initialRoute,
          circleListArgs: CircleSheetArgs(
            circleList: circleList,
            onCircleTap: (circle) {
              Navigator.pop(modalContext); // Close the modal
              onCircleTap(circle); // Trigger the callback
            },
          ),
          addCircleArgs: AddCircleArgs(
            showBack: onShowBack,
            onAddedCircle: () {
              Navigator.pop(modalContext); // Close the modal
              onCircleCreated(); // Trigger the callback
            },
          ),
          joinCircleArgs: JoinCircleArgs(
            showBack: onShowBack,
            onJoinedCircle: () {
              Navigator.pop(modalContext); // Close the modal
              onJoinedCircle(); // Trigger the callback
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onShowCircleModal(context: context, initialRoute: null),
      child: Column(
        children: [
          if (!hasCircle) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextWidgets.mainRegular(
                        title:
                            'You need to create a circle to enable location sharing and tracking.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ConfirmButton(
                              onClick: () {
                                onShowCircleModal(
                                    context: context,
                                    initialRoute: '/add-circle',
                                    onShowBack: false);
                              },
                              title: 'Create circle',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ConfirmButton(
                              onClick: () {
                                onShowCircleModal(
                                    context: context,
                                    initialRoute: '/join-circle',
                                    onShowBack: false);
                              },
                              title: 'Join circle',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child:
                      TextWidgets.mainBold(title: circleName!, fontSize: 18.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
