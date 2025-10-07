import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';

class CircleBottomSheet extends StatelessWidget {
  final bool hasCircle;
  final CircleModel? circle;
  final List<CircleMembersModel> members;
  final Function(CircleModel) onCircleTap;
  final VoidCallback onCreateCircle;

  const CircleBottomSheet({
    super.key,
    required this.members,
    required this.onCircleTap,
    required this.hasCircle,
    required this.circle,
    required this.onCreateCircle,
  });

  @override
  Widget build(BuildContext context) {
    print('members count: ${members.length}');
    print('circle created by: ${circle?.createdBy}');

    // Safe access to owner name
    String ownerName = 'Unknown';
    if (members.isNotEmpty && circle?.createdBy != null) {
      try {
        final owner = members.firstWhere(
          (member) => member.userId == circle!.createdBy,
          orElse: () =>
              CircleMembersModel(userId: '', name: 'Unknown', role: ''),
        );
        ownerName = owner.name;
      } catch (e) {
        print('Error finding owner: $e');
        ownerName = 'Unknown';
      }
    }

    if (!hasCircle || circle == null) {
      return Card(
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidgets.mainBold(title: circle!.name, fontSize: 20.0),
            const SizedBox(height: 8),
            TextWidgets.mainSemiBold(title: 'Created by: $ownerName'),
            TextWidgets.mainSemiBold(
                title: 'Created at: ${circle!.dateCreated.toString()}',
                textAlign: TextAlign.start),
          ],
        ),
      ),
    );
  }
}
