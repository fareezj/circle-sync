// Example of how to use the enhanced PostModel with creator names

import 'package:flutter/material.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/features/map/presentation/providers/posts_manager.dart';

/// Example widget showing how to display posts with creator names
class PostListWidget extends StatelessWidget {
  final Map<String, PostModel> posts;

  const PostListWidget({
    super.key,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts.values.elementAt(index);

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(post.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display creator name - this is now automatically available!
                Text(
                  'By: ${post.creatorName ?? "Unknown User"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${post.lat.toStringAsFixed(4)}, ${post.lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Posted: ${post.formattedCreatedAt}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            leading: post.hasImage
                ? const Icon(Icons.image, color: Colors.green)
                : const Icon(Icons.location_on, color: Colors.blue),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show post options
                _showPostOptions(context, post);
              },
            ),
          ),
        );
      },
    );
  }

  void _showPostOptions(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Created by ${post.creatorName ?? "Unknown User"}'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text('Posted ${post.formattedCreatedAt}'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(
                  '${post.lat.toStringAsFixed(6)}, ${post.lng.toStringAsFixed(6)}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to manually get posts with creator names for initial loading
class PostService {
  static Future<void> loadInitialPostsExample(String circleId) async {
    final postsManager = PostsManager();

    try {
      // Get posts with creator names for initial loading
      final postsWithCreators =
          await postsManager.getPostsWithCreatorNames(circleId);

      // Use the posts - creator names are already included
      for (final post in postsWithCreators.values) {
        print('Post: ${post.name}');
        print('Creator: ${post.creatorName ?? "Unknown"}');
        print('---');
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }
}

/// Example of filtering posts by creator name
extension PostFiltering on Map<String, PostModel> {
  /// Filter posts by creator name
  Map<String, PostModel> filterByCreator(String creatorName) {
    return Map.fromEntries(
      entries.where((entry) =>
          entry.value.creatorName
              ?.toLowerCase()
              .contains(creatorName.toLowerCase()) ??
          false),
    );
  }

  /// Get all unique creator names from posts
  Set<String> getCreatorNames() {
    return values.map((post) => post.creatorName ?? "Unknown User").toSet();
  }

  /// Group posts by creator
  Map<String, List<PostModel>> groupByCreator() {
    final Map<String, List<PostModel>> grouped = {};

    for (final post in values) {
      final creatorName = post.creatorName ?? "Unknown User";
      grouped.putIfAbsent(creatorName, () => []).add(post);
    }

    return grouped;
  }
}
