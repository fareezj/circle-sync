import 'package:flutter/material.dart';

class CircleInfoCard extends StatelessWidget {
  final bool hasCircle;
  final String? circleName;
  final VoidCallback onCreateCircle;

  const CircleInfoCard({
    super.key,
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

    return Positioned(
      top: 16,
      left: 16,
      child: Card(
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            circleName!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
