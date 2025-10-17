import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/models/post_model.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:circle_sync/features/circles/data/datasources/circle_service.dart';
import 'package:latlong2/latlong.dart';

class PostsBottomSheet extends StatelessWidget {
  final Map<String, PostModel> posts;
  final String circleId;
  final Function(LatLng) onPostSelected;
  final Function(String) onMemberAdded;

  const PostsBottomSheet({
    super.key,
    required this.posts,
    required this.circleId,
    required this.onPostSelected,
    required this.onMemberAdded,
  });

  void _showAddMemberDialog(BuildContext context) {
    final TextEditingController userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member to Circle'),
          content: TextField(
            controller: userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Enter the user ID to add',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final userId = userIdController.text.trim();
                if (userId.isNotEmpty) {
                  try {
                    final circleService = CircleService();
                    await circleService.addMember(circleId, userId);
                    onMemberAdded(userId);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Member added successfully!')),
                    );
                  } catch (e) {
                    debugPrint('Error adding member: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add member.')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextWidgets.mainBold(title: 'Posts', fontSize: 20.0),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: posts.length,
              physics: ClampingScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                List<PostModel> post = posts.values.toList();
                return Column(
                  children: [
                    ListTile(
                      title: Text(post[index].name),
                      leading: const Icon(Icons.photo_size_select_actual),
                      onTap: () {
                        final postLocation =
                            LatLng(post[index].lat, post[index].lng);
                        onPostSelected(postLocation);
                      },
                    ),
                    if (index == posts.length - 1) const Divider()
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
