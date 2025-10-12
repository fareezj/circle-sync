import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/map/presentation/providers/map_providers.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircleBottomSheet extends StatelessWidget {
  final VoidCallback onCreateCircle;

  const CircleBottomSheet({
    super.key,
    required this.onCreateCircle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Consumer(
        builder: (context, ref, child) {
          final circleName = ref.watch(mapNotifierProvider).circleName;
          print('circleName: $circleName');
          final hasCircle = ref.watch(mapNotifierProvider).hasCircle;
          print('hasCircle: $hasCircle');
          final circleMembers = ref.watch(mapNotifierProvider).circleMembers;
          print('circleMembers: $circleMembers');
          // final circle = ref
          //     .watch(mapNotifierProvider)
          //     .joinedCircles
          //     .where(
          //         (e) => e.id == ref.watch(mapNotifierProvider).currentCircleId)
          //     .first;
          // print('circle: $circle');

          // Safe access to owner name
          String ownerName = 'Unknown';
          // if (circleMembers.isNotEmpty) {
          //   try {
          //     final owner = circleMembers.firstWhere(
          //       (member) => member.userId == circle.createdBy,
          //       orElse: () =>
          //           CircleMembersModel(userId: '', name: 'Unknown', role: ''),
          //     );
          //     ownerName = owner.name;
          //   } catch (e) {
          //     ownerName = 'Unknown';
          //   }
          // }

          if (!hasCircle) {
            return Card(
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hasCircle.toString()),
                    const Text(
                      'You need to create a circle to enable location sharing and tracking.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: onCreateCircle,
                      child: const Text('Create Circle'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidgets.mainBold(title: circleName ?? '-', fontSize: 20.0),
                const SizedBox(height: 8),
                TextWidgets.mainSemiBold(title: 'Created by: $ownerName'),
                // TextWidgets.mainSemiBold(
                //     title: 'Created at: ${circle.dateCreated.toString()}',
                //     textAlign: TextAlign.start),
              ],
            ),
          );
        },
      ),
    );
  }
}
