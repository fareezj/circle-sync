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
    final newCircle = CircleModel(
      id: circleRef.id,
      name: name,
      createdBy: currentUserId,
      dateCreated: DateTime.now(),
      members: [currentUserId, ...memberIds],
    );

    await circleRef.set(newCircle.toMap());

    return circleRef.id;
  }

  Future<CircleModel> getCircle(String circleId) async {
    final doc = await _firestore.collection('circles').doc(circleId).get();
    if (!doc.exists) {
      throw Exception('Circle not found');
    }
    return CircleModel.fromDocument(doc);
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

    // Add the user to the circle's members list
    await _firestore.collection('circles').doc(circleId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('circleInvitations').doc(invitationId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CircleModel>> getUserCircles(String userId) async {
    final querySnapshot = await _firestore
        .collection('circles')
        .where('members', arrayContains: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => CircleModel.fromDocument(doc))
        .toList();
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
        final circle = CircleModel.fromDocument(circleDoc);
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

  Future<Map<String, dynamic>> getCircleInfo() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return {
        'joinedCircles': <CircleModel>[],
        'invitations': <Map<String, dynamic>>[],
      };
    }

    final circleService = CircleService();
    final joinedCircles = await circleService.getUserCircles(currentUserId);
    final invitations = await circleService.getInvitations(currentUserId);

    return {
      'joinedCircles': joinedCircles,
      'invitations': invitations,
    };
  }
}
