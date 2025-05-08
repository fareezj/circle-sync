import 'package:circle_sync/features/circles/data/models/circle_model.dart';
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Circle Members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddMemberDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final memberId = members[index].userId;
                return ListTile(
                  title: Text(members[index].name),
                  onTap: () {
                    final memberLocation = otherUsersLocations[memberId];
                    if (memberLocation != null) {
                      onMemberSelected(memberId);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Location not available for this member.')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
