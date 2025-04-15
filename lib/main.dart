import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/screens/login_page.dart';
import 'package:circle_sync/route_generator.dart';
import 'package:circle_sync/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Circle Sync Location Service',
      channelDescription: 'Keeps Circle Sync running in the background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: true, // Restart on device reboot (Android)
      allowWifiLock: true, eventAction: ForegroundTaskEventAction.repeat(500),
    ),
  );
  runApp(ProviderScope(child: const CircleSync()));
}

class CircleSync extends ConsumerStatefulWidget {
  const CircleSync({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CircleSyncState();
}

class _CircleSyncState extends ConsumerState<CircleSync> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: RouteGenerator.generateRoute,
      home: Consumer(
        builder: (context, ref, child) {
          final isLoggedInProvider = ref.watch(getIsLoggedInProvider.future);
          return FutureBuilder(
            future: isLoggedInProvider,
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data ?? false;
              return isLoggedIn == 'true'
                  ? const MainPage()
                  : const LoginPage();
            },
          );
        },
      ),
    );
  }
}
