import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/screens/widgets/post_marker.dart';

/// Example demonstrating how PostMarker now shows different colors for different users
class PostMarkerColorsExample extends ConsumerWidget {
  const PostMarkerColorsExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create sample posts from different users to see color differences
    final samplePosts = [
      PostModel(
        id: '1',
        circleId: 'circle1',
        userId: 'user_john', // Different users will get different colors
        name: 'Beautiful sunset',
        lat: 37.7749,
        lng: -122.4194,
        createdBy: 'user_john',
        creatorName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PostModel(
        id: '2',
        circleId: 'circle1',
        userId: 'user_alice', // Different user = different color
        name: 'Coffee shop',
        lat: 37.7849,
        lng: -122.4294,
        createdBy: 'user_alice',
        creatorName: 'Alice Smith',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PostModel(
        id: '3',
        circleId: 'circle1',
        userId: 'user_bob', // Different user = different color
        name: 'Park visit',
        lat: 37.7949,
        lng: -122.4394,
        createdBy: 'user_bob',
        creatorName: 'Bob Johnson',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PostModel(
        id: '4',
        circleId: 'circle1',
        userId: 'user_john', // Same user as first = same color
        name: 'Another sunset',
        lat: 37.8049,
        lng: -122.4494,
        createdBy: 'user_john',
        creatorName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Marker Colors Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post Markers with User-Specific Colors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Each user gets a consistent, unique color:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Display markers in a grid to show color differences
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: samplePosts
                  .map((post) => Column(
                        children: [
                          // Show the marker
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: PostMarker(post: post, ref: ref),
                          ),
                          const SizedBox(height: 8),
                          // Show user info
                          Text(
                            post.creatorName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            post.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ))
                  .toList(),
            ),

            const SizedBox(height: 30),
            const Text(
              'Color Assignment Rules:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
                '• Each user ID gets a consistent color from a palette of 15 colors'),
            const Text(
                '• Same user = same color (like John\'s two posts above)'),
            const Text('• Different users = different colors'),
            const Text('• Colors are generated using a hash of the user ID'),
            const Text('• If user ID is empty, falls back to default blue'),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎨 Implementation Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Uses PostModel.userId for color generation'),
                  Text('• 15-color palette ensures good variety'),
                  Text('• Colors are readable with white icons'),
                  Text('• Consistent across app restarts'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
