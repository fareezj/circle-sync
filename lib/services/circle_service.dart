import 'package:circle_sync/models/circle_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CircleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createCircle(String name, List<String> memberIds) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final circleRef = _firestore.collection('circles').doc();
    final newCircle = Circle(
      id: circleRef.id,
      name: name,
      createdBy: currentUserId,
      dateCreated: DateTime.now(),
      members: [
        currentUserId,
        ...memberIds
      ], // Optional: can be removed if using circleMemberships
    );

    await circleRef.set(newCircle.toMap());

    // Add the creator to the circleMemberships subcollection
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('circleMemberships')
        .doc(circleRef.id)
        .set({
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    // Set as the creator's current circle
    await setUserCurrentCircle(currentUserId, circleRef.id);

    return circleRef.id;
  }

  Future<Circle> getCircle(String circleId) async {
    final doc = await _firestore.collection('circles').doc(circleId).get();
    if (!doc.exists) {
      throw Exception('Circle not found');
    }
    return Circle.fromDocument(doc);
  }

  Future<void> addMember(String circleId, String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Create an invitation in the circleInvitations collection
    final invitationRef = _firestore.collection('circleInvitations').doc();
    await invitationRef.set({
      'circleId': circleId,
      'userId': userId,
      'invitedBy': currentUserId,
      'status': 'pending',
      'invitedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptInvitation(String invitationId, String userId) async {
    // Update the invitation status
    await _firestore.collection('circleInvitations').doc(invitationId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Get the circleId from the invitation
    final invitationDoc = await _firestore
        .collection('circleInvitations')
        .doc(invitationId)
        .get();
    final circleId = invitationDoc.data()!['circleId'] as String;

    // Add the user to the circle's members list (optional)
    await _firestore.collection('circles').doc(circleId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    // Add the circle to the user's circleMemberships
    await setUserCurrentCircle(userId, circleId);
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('circleInvitations').doc(invitationId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserCurrentCircle(String userId, String circleId) async {
    // Deactivate all other circles
    final memberships = await _firestore
        .collection('users')
        .doc(userId)
        .collection('circleMemberships')
        .get();
    for (var doc in memberships.docs) {
      await doc.reference.update({'isActive': false});
    }

    // Activate the selected circle (and add to memberships if not already there)
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('circleMemberships')
        .doc(circleId)
        .set({
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    }, SetOptions(merge: true));
  }

  Future<List<Circle>> getUserCircles(String userId) async {
    final memberships = await _firestore
        .collection('users')
        .doc(userId)
        .collection('circleMemberships')
        .get();

    final circleIds = memberships.docs.map((doc) => doc.id).toList();
    if (circleIds.isEmpty) return [];

    final querySnapshot = await _firestore
        .collection('circles')
        .where(FieldPath.documentId, whereIn: circleIds)
        .get();

    return querySnapshot.docs.map((doc) => Circle.fromDocument(doc)).toList();
  }

  Future<List<Map<String, dynamic>>> getInvitations(String userId) async {
    final invitations = await _firestore
        .collection('circleInvitations')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();

    final List<Map<String, dynamic>> invitationDetails = [];
    for (var doc in invitations.docs) {
      final data = doc.data();
      final circleId = data['circleId'] as String;
      final circleDoc =
          await _firestore.collection('circles').doc(circleId).get();
      if (circleDoc.exists) {
        final circle = Circle.fromDocument(circleDoc);
        invitationDetails.add({
          'invitationId': doc.id,
          'circle': circle,
          'invitedBy': data['invitedBy'],
          'invitedAt': (data['invitedAt'] as Timestamp?)?.toDate(),
        });
      }
    }
    return invitationDetails;
  }
}
