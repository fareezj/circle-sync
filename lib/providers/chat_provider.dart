import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'package:flutter/widgets.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Message> _messages = [];
  String? _currentChatRoomId;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _messageSubscription;

  ChatProvider();

  List<Message> get messages => _messages;
  String? get errorMessage => _errorMessage;

  void setChatRoom(String chatRoomId) {
    _messageSubscription?.cancel();
    _messages.clear();
    _currentChatRoomId = chatRoomId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageSubscription = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((querySnapshot) {
        for (var change in querySnapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            _messages.add(Message.fromFirestore(change.doc));
          }
        }
        notifyListeners();
      });
    });
  }

  Future<void> sendMessage(String text, String senderId) async {
    if (_currentChatRoomId == null) return;
    if (text.isEmpty || senderId.isEmpty) {
      _errorMessage = 'Message cannot be empty';
      notifyListeners();
      return;
    }
    try {
      await _firestore
          .collection('chatRooms')
          .doc(_currentChatRoomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }
}
