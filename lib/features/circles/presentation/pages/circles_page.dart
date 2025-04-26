import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/services/circle_service.dart';
import 'package:circle_sync/services/location_fg.dart';
import 'package:circle_sync/services/permissions.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:circle_sync/route_generator.dart';

class CirclesPage extends ConsumerStatefulWidget {
  const CirclesPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CirclesPageState();
}

class _CirclesPageState extends ConsumerState<CirclesPage> {
  final CircleService circleService = CircleService();
  bool _isTracking = false;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    LocationTask.initForegroundTask();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final user = _supabase.auth.currentUser;
          if (user != null) {
            _showCreateCircleDialog(context, user.id);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidgets.mainBold(title: 'Your Circles', fontSize: 24.0),
                FutureBuilder<Map<String, dynamic>>(
                  future: circleService.getCircleInfo(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final joinedCircles =
                        snapshot.data!['joinedCircles'] as List<CircleModel>;
                    final invitations = snapshot.data!['invitations']
                        as List<Map<String, dynamic>>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleTracking,
                          child: Text(
                              _isTracking ? 'Stop Tracking' : 'Start Tracking'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: TextWidgets.mainSemiBold(
                              title: 'Joined Circles', fontSize: 18.0),
                        ),
                        if (joinedCircles.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: TextWidgets.mainSemiBold(
                                title: 'You have not joined any circles.'),
                          ),
                        ...joinedCircles.map((circle) => ListTile(
                              title: TextWidgets.mainSemiBold(
                                  title: circle.name,
                                  textAlign: TextAlign.start),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () {
                                _showCircleOptionsDialog(
                                    context, circle.id, circle.name);
                              },
                            )),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: TextWidgets.mainSemiBold(
                              title: 'Circle Invitations', fontSize: 18.0),
                        ),
                        if (invitations.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: TextWidgets.mainSemiBold(
                                title: 'You have no pending invitations'),
                          ),
                        ...invitations.map((inv) {
                          final circle = inv['circle'] as CircleModel;
                          final invitedBy = inv['invitedBy'] as String;
                          final invitationId = inv['invitationId'] as String;
                          return ListTile(
                            title: Text(circle.name),
                            subtitle: Text('Invited by: $invitedBy'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () async {
                                    await circleService
                                        .acceptInvitation(invitationId);
                                    Navigator.pushNamed(
                                      context,
                                      RouteGenerator.mapPage,
                                      arguments: {'circleId': circle.id},
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await circleService
                                        .declineInvitation(invitationId);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTracking() async {
    if (!_isTracking) {
      bool hasPermissions = await Permissions.requestLocationPermissions();
      if (hasPermissions) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        print('here3.1: $userId');

        try {
          final resp = await Supabase.instance.client
              .from('circles')
              .select('circle_id')
              .contains('members', '["$userId"]');

          final circleIds =
              (resp as List).map((r) => r['circle_id'] as String).toList();

          print('here3');

          await LocationTask.initForegroundTask();
          await LocationTask.startForegroundTask(
            userId: userId,
            circleIds: circleIds,
          );
          setState(() => _isTracking = true);
        } catch (e) {
          print('error: $e');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions denied')),
        );
      }
    } else {
      await LocationTask.stopForegroundTask();
      setState(() => _isTracking = false);
    }
  }

  Future<void> _showCreateCircleDialog(
      BuildContext context, String userId) async {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final circleName = nameController.text.trim();
              if (circleName.isNotEmpty) {
                try {
                  final circleId =
                      await circleService.createCircle(circleName, []);
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    RouteGenerator.mapPage,
                    arguments: {'circleId': circleId},
                  );
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
      ),
    );
  }

  Future<void> _showCircleOptionsDialog(
      BuildContext context, String circleId, String circleName) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Circle: $circleName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  RouteGenerator.mapPage,
                  arguments: {'circleId': circleId},
                );
              },
              child: const Text('Go to Map'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = _supabase.auth.currentUser;
                if (user != null) {
                  // Remove the member from the circle
                  final circle = await circleService.getCircle(circleId);
                  final updatedMembers = List<String>.from(circle.members)
                    ..remove(user.id);
                  await _supabase.from('circles').update(
                      {'members': updatedMembers}).eq('circle_id', circleId);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Leave Circle'),
            ),
          ],
        ),
      ),
    );
  }
}
