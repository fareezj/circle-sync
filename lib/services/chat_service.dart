import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Message>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String text,
    required String senderId,
  }) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // lib/services/chat_service.dart
  Future<void> createNewChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = _generateChatId(currentUserId, otherUserId);

    await _firestore.collection('chatRooms').doc(chatId).set({
      'participants': [currentUserId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // lib/services/chat_service.dart
  Future<void> createNewChatIfNeeded(
      String chatRoomId, String currentUserId) async {
    final doc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
    if (!doc.exists) {
      await _firestore.collection('chatRooms').doc(chatRoomId).set({
        'participants': [currentUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _generateChatId(String a, String b) {
    final sortedIds = [a, b]..sort();
    return sortedIds.join('_');
  }
}
