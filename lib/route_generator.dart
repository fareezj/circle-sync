import 'package:circle_sync/screens/login_page.dart';
import 'package:circle_sync/screens/main_screen.dart';
import 'package:circle_sync/screens/register_page.dart';
import 'package:flutter/material.dart';
import 'package:circle_sync/screens/users_screen.dart';
import 'package:circle_sync/screens/map_page.dart';
import 'package:circle_sync/screens/chat_screen.dart';

class RouteGenerator {
  static const String loginPage = '/login';
  static const String mainPage = '/main';
  static const String homePage = '/home';
  static const String chatPage = '/chat';
  static const String registerPage = '/registerPage';
  static const String mapPage = '/mapPage';
  static const String usersPage = '/usersPage';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteGenerator.mainPage:
        return MaterialPageRoute(builder: (_) => const MainPage());
      case RouteGenerator.loginPage:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case RouteGenerator.registerPage:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case usersPage:
        return MaterialPageRoute(builder: (_) => const UsersScreen());
      case mapPage:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MapPage(circleId: args?['circleId'] as String?),
        );
      case chatPage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            user: args['user'],
            chatRoomId: args['chatRoomId'],
            otherUserId: args['otherUserId'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
