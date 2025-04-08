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
      members: [currentUserId, ...memberIds],
    );

    await circleRef.set(newCircle.toMap());
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
    await _firestore.collection('circles').doc(circleId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> setUserCurrentCircle(String userId, String circleId) async {
    await _firestore.collection('users').doc(userId).set({
      'currentCircleId': circleId,
    }, SetOptions(merge: true));
  }
}
