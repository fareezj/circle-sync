import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  
  const ErrorScreen({super.key, required this.message});

  static Route<dynamic> route(String message) {
    return MaterialPageRoute(builder: (_) => ErrorScreen(message: message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text(message),
      ),
    );
  }
}
