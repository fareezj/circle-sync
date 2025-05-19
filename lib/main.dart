import 'dart:io';

import 'package:circle_sync/features/map/presentation/pages/map_page.dart';
import 'package:circle_sync/features/map/presentation/pages/native_geofence.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/features/authentication/presentation/pages/login_page.dart';
import 'package:circle_sync/route_generator.dart';
import 'package:circle_sync/features/base/presentation/pages/main_screen.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NativeGeofenceManager.instance.initialize();

  final appDocDir = await getApplicationDocumentsDirectory();
  final hivePath = appDocDir.path;

  // initialize Hive once in your UI isolate
  Hive.init(hivePath);
  await Hive.openBox('tracker');

  // you can also persist this path for the background isolate:
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('hivePath', hivePath);

  // Enable verbose logging for debugging (remove in production)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  // Initialize with your OneSignal App ID
  OneSignal.initialize("ffd7d2ef-4055-4fa8-9916-06dfaeca6cf0");
  // Use this method to prompt for push notifications.
  // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
  OneSignal.Notifications.requestPermission(false);

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

  await Supabase.initialize(
    url: 'https://hnbqegfgzwugkdtfysma.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuYnFlZ2Znend1Z2tkdGZ5c21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTE2NjQsImV4cCI6MjA2MDcyNzY2NH0.l_RqDcUmqvB_MRJ3VG-VQJcjVXqlKeQPghoEy5awTGc',
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
