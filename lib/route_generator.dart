import 'package:circle_sync/register_page.dart';
import 'package:circle_sync/screens/error_screen.dart';
import 'package:circle_sync/screens/map_page.dart';
import 'package:flutter/material.dart';
import '../login_page.dart';
import '../home_page.dart';
import '../screens/chat_screen.dart';
import '../models/user.dart'; // assuming User model is defined in this file

class RouteGenerator {
  static const String loginPage = '/login';
  static const String homePage = '/home';
  static const String chatPage = '/chat';
  static const String registerPage = '/registerPage';
  static const String mapPage = '/mapPage';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteGenerator.loginPage:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case RouteGenerator.homePage:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case RouteGenerator.registerPage:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case RouteGenerator.mapPage:
        return MaterialPageRoute(builder: (_) => const MapPage());
      case RouteGenerator.chatPage:
        if (settings.arguments is! Map<String, dynamic>) {
          return ErrorScreen.route('Invalid chat parameters format');
        }
        final args = settings.arguments as Map<String, dynamic>;

        try {
          final user = args['user'] as AppUser;
          final chatRoomId = args['chatRoomId'] as String;
          final otherUserId = args['otherUserId'] as String;

          return MaterialPageRoute(
              builder: (_) => ChatScreen(
                    user: user,
                    chatRoomId: chatRoomId,
                    otherUserId: otherUserId,
                  ));
        } catch (e) {
          return ErrorScreen.route(
              'Missing or invalid chat parameters: ${e.toString()}');
        }
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
