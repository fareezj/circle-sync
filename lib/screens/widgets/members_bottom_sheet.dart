import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:circle_sync/features/circles/data/datasources/circle_service.dart';
import 'package:latlong2/latlong.dart';

class MembersBottomSheet extends StatelessWidget {
  final List<CircleMembersModel> members;
  final String circleId;
  final Map<String, LatLng> otherUsersLocations;
  final Function(String) onMemberSelected;
  final Function(String) onMemberAdded;

  const MembersBottomSheet({
    super.key,
    required this.members,
    required this.circleId,
    required this.otherUsersLocations,
    required this.onMemberSelected,
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
            child:
                TextWidgets.mainBold(title: 'Circle Members', fontSize: 20.0),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: members.length,
              physics: ClampingScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final memberId = members[index].userId;
                return Column(
                  children: [
                    ListTile(
                      title: Text(members[index].name),
                      leading: const Icon(Icons.person),
                      onTap: () {
                        final memberLocation = otherUsersLocations[memberId];
                        if (memberLocation != null) {
                          onMemberSelected(memberId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Location not available for this member.')),
                          );
                        }
                      },
                    ),
                    if (index == members.length - 1) const Divider()
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
