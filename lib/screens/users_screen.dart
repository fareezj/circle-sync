import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../route_generator.dart';
import '../services/circle_service.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  Future<Map<String, dynamic>> _getCircleInfo() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return {
        'currentCircleId': null,
        'currentCircleName': null,
        'joinedCircles': <Circle>[],
        'invitedCircles': <Circle>[],
      };
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final currentCircleId = userDoc.data()?['currentCircleId'] as String?;

    String? currentCircleName;
    if (currentCircleId != null) {
      final circleDoc = await FirebaseFirestore.instance
          .collection('circles')
          .doc(currentCircleId)
          .get();
      currentCircleName = circleDoc.data()?['name'] as String?;
    }

    final circleService = CircleService();
    final joinedCircles = await circleService.getUserCircles(currentUserId);
    final invitedCircles = await circleService.getInvitedCircles(currentUserId);

    return {
      'currentCircleId': currentCircleId,
      'currentCircleName': currentCircleName,
      'joinedCircles': joinedCircles,
      'invitedCircles': invitedCircles,
    };
  }

  Future<void> _showCreateCircleDialog(
      BuildContext context, String userId) async {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create a Circle'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Circle Name',
              hintText: 'Enter a name for your circle',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final circleName = nameController.text.trim();
                if (circleName.isNotEmpty) {
                  try {
                    final circleService = CircleService();
                    final circleId =
                        await circleService.createCircle(circleName, []);
                    await circleService.setUserCurrentCircle(userId, circleId);
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, RouteGenerator.mapPage);
                  } catch (e) {
                    debugPrint('Error creating circle: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create circle.')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCircleOptionsDialog(BuildContext context, String userId,
      String circleId, String? circleName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Circle: ${circleName ?? "Unknown"}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final circleService = CircleService();
                  await circleService.setUserCurrentCircle(userId, circleId);
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, RouteGenerator.mapPage);
                },
                child: const Text('Go to Map'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .update({'currentCircleId': null});
                  Navigator.of(context).pop();
                },
                child: const Text('Leave Circle'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateChatId(String a, String b) {
    final sortedIds = [a, b]..sort();
    return sortedIds.join('_');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getCircleInfo(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }

              final currentCircleId =
                  snapshot.data!['currentCircleId'] as String?;
              final currentCircleName =
                  snapshot.data!['currentCircleName'] as String?;
              final joinedCircles =
                  snapshot.data!['joinedCircles'] as List<Circle>;
              final invitedCircles =
                  snapshot.data!['invitedCircles'] as List<Circle>;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentCircleId != null)
                      ListTile(
                        title: Text(
                            'Current Circle: ${currentCircleName ?? "Unknown"}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUserId != null) {
                            _showCircleOptionsDialog(context, currentUserId,
                                currentCircleId, currentCircleName);
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    const Text('Joined Circles',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    if (joinedCircles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('You have not joined any circles.'),
                      ),
                    ...joinedCircles.map((circle) => ListTile(
                          title: Text(circle.name),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
                            final currentUserId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (currentUserId != null) {
                              _showCircleOptionsDialog(context, currentUserId,
                                  circle.id, circle.name);
                            }
                          },
                        )),
                    const SizedBox(height: 8),
                    const Text('Invited Circles',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    if (invitedCircles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('You have no pending invitations.'),
                      ),
                    ...invitedCircles.map((circle) => ListTile(
                          title: Text(circle.name),
                          trailing: const Icon(Icons.add),
                          onTap: () async {
                            final currentUserId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (currentUserId != null) {
                              final circleService = CircleService();
                              await circleService.setUserCurrentCircle(
                                  currentUserId, circle.id);
                              Navigator.pushNamed(
                                  context, RouteGenerator.mapPage);
                            }
                          },
                        )),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final currentUserId =
                            FirebaseAuth.instance.currentUser?.uid;
                        if (currentUserId != null) {
                          _showCreateCircleDialog(context, currentUserId);
                        }
                      },
                      child: const Text('Create New Circle'),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final users =
                    snapshot.data!.docs.where((doc) => doc.id != currentUserId);

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users.elementAt(index);
                    if (user['name'] == null) {
                      return const ListTile(
                        title: Text('Invalid user data',
                            style: TextStyle(color: Colors.red)),
                      );
                    }
                    return ListTile(
                      leading: CircleAvatar(child: Text(user['name'][0])),
                      title: Text(user['name']),
                      onTap: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        final chatRoomId = _generateChatId(
                            currentUser!.uid.toString(), user['uid']);

                        Navigator.pushNamed(
                          context,
                          RouteGenerator.chatPage,
                          arguments: {
                            'user': AppUser(
                              name: user['name'],
                              email: user['email'],
                              id: user.id,
                            ),
                            'chatRoomId': chatRoomId,
                            'otherUserId': user.id,
                          },
                        );
                      },
                    );
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
