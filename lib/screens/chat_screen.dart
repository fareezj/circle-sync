import 'package:circle_sync/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatelessWidget {
  final AppUser user;
  final String chatRoomId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.user,
    required this.chatRoomId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setChatRoom(chatRoomId);
    });

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) => ListView.builder(
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final message = provider.messages[index];
                  return ListTile(
                    title: Text(message.text),
                    subtitle: Text(message.senderId),
                    trailing: Text(
                      '${message.timestamp.hour}:${message.timestamp.minute}',
                    ),
                  );
                },
              ),
            ),
          ),
          _MessageInput(chatRoomId: chatRoomId),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final String chatRoomId;

  const _MessageInput({required this.chatRoomId});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _controller = TextEditingController();

  Future<void> _sendMessage() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.sendMessage(_controller.text, widget.chatRoomId);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () async {
              if (_controller.text.isNotEmpty && user != null) {
                await _sendMessage();
              }
            },
          ),
        ],
      ),
    );
  }
}
