import 'package:circle_sync/features/account/presentation/pages/permission_settings_page.dart';
import 'package:circle_sync/features/circles/presentation/pages/circles_page.dart';
import 'package:circle_sync/features/authentication/presentation/pages/login_page.dart';
import 'package:circle_sync/features/base/presentation/pages/main_screen.dart';
import 'package:circle_sync/features/authentication/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:circle_sync/features/map/presentation/pages/map_page.dart';
import 'package:circle_sync/screens/chat_screen.dart';
import 'package:circle_sync/screens/settings_screen.dart';

class RouteGenerator {
  static const String loginPage = '/login';
  static const String mainPage = '/main';
  static const String homePage = '/home';
  static const String chatPage = '/chat';
  static const String registerPage = '/registerPage';
  static const String mapPage = '/mapPage';
  static const String usersPage = '/usersPage';
  static const String circlePage = '/circlePage';
  static const String permissionSettings = '/permissionSettings';
  static const String settingsPage = '/settingsPage';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteGenerator.mainPage:
        return MaterialPageRoute(builder: (_) => const MainPage());
      case RouteGenerator.loginPage:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case RouteGenerator.permissionSettings:
        return MaterialPageRoute(
            builder: (_) => const PermissionsSettingsPage());
      case RouteGenerator.registerPage:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case RouteGenerator.circlePage:
        return MaterialPageRoute(builder: (_) => const CirclesPage());
      case usersPage:
        return MaterialPageRoute(builder: (_) => const CirclesPage());
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
      case settingsPage:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
