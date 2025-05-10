import 'package:circle_sync/features/map/presentation/pages/widgets/circle_list_sheet.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:flutter/material.dart';

class CircleInfoCard extends StatelessWidget {
  final bool hasCircle;
  final String? circleName;
  List<CircleModel> circleList;
  final Function(CircleModel) onCircleTap;
  final VoidCallback onCreateCircle;

  CircleInfoCard({
    super.key,
    required this.onCircleTap,
    required this.circleList,
    required this.hasCircle,
    required this.circleName,
    required this.onCreateCircle,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCircle) {
      return Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Card(
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
        ),
      );
    }

    if (circleName == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => CircleListSheet(
            circleList: circleList,
            onCircleTap: (p0) => onCircleTap(p0),
          ),
        );
      },
      child: Positioned(
        top: 16,
        left: 16,
        child: Card(
          color: Colors.white.withOpacity(0.9),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              circleName!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
