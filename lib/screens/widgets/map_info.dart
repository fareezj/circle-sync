import 'package:circle_sync/models/user.dart';
import 'package:circle_sync/route_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

String _generateChatId(String a, String b) {
  final sortedIds = [a, b]..sort();
  return sortedIds.join('_');
}

void showCurrentUserInfoDialog(BuildContext context, LatLng location) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return;

  // Fetch current user details from Firestore
  FirebaseFirestore.instance.collection('users').doc(currentUserId).get().then(
    (userDoc) {
      String username = 'Me';
      String email = '';

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('name')) {
          username = data['name'] as String;
        }
        if (data != null && data.containsKey('email')) {
          email = data['email'] as String;
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('My Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Username: $username'),
              const SizedBox(height: 8),
              Text('User ID: $currentUserId'),
              const SizedBox(height: 8),
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
              const Text('This is your current location',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
  ).catchError((error) {
    // Show a simpler dialog if we can't fetch user details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $currentUserId'),
            const SizedBox(height: 8),
            Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            const Text('This is your current location',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  });
}

void showUserInfoDialog(BuildContext context, String userId, LatLng location) {
  debugPrint('Showing info dialog for user: $userId at location: $location');

  // Fetch user details from Firestore if available
  FirebaseFirestore.instance.collection('users').doc(userId).get().then(
    (userDoc) {
      debugPrint('User document exists: ${userDoc.exists}');
      if (userDoc.exists) {
        debugPrint('User data: ${userDoc.data()}');
      }

      String username = 'Unknown User';
      String email = '';

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('name')) {
          username = data['name'] as String;
        }
        if (data != null && data.containsKey('email')) {
          email = data['email'] as String;
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('User Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Username: $username'),
              const SizedBox(height: 8),
              Text('User ID: $userId'),
              const SizedBox(height: 8),
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId != null) {
                  final chatRoomId = _generateChatId(currentUserId, userId);

                  // Create an AppUser object as required by the route generator
                  final user = AppUser(
                    id: userId,
                    name: username,
                    email: email,
                  );

                  // Close dialog first
                  Navigator.of(context).pop();

                  // Then navigate to chat using the correct route name from RouteGenerator
                  Navigator.pushNamed(
                    context,
                    RouteGenerator.chatPage,
                    arguments: {
                      'user': user,
                      'chatRoomId': chatRoomId,
                      'otherUserId': userId,
                    },
                  );
                }
              },
              child: const Text('Chat'),
            ),
          ],
        ),
      );
    },
  ).catchError((error) {
    debugPrint('Error fetching user data: $error');

    // Show a simpler dialog if we can't fetch user details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: $userId'),
            const SizedBox(height: 8),
            Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  });
}
