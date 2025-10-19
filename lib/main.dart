import 'package:circle_sync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/features/authentication/presentation/pages/login_page.dart';
import 'package:circle_sync/route_generator.dart';
import 'package:circle_sync/features/base/presentation/pages/main_screen.dart';
import 'package:circle_sync/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// REMOVED: flutter_foreground_task - causes App Store rejection
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// REMOVED: native_geofence - causes App Store rejection
// REMOVED: onesignal_flutter - third-party data collection risk
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // REMOVED: NativeGeofenceManager initialization - causes App Store rejection

  final appDocDir = await getApplicationDocumentsDirectory();
  final hivePath = appDocDir.path;

  // initialize Hive once in your UI isolate
  Hive.init(hivePath);
  await Hive.openBox('tracker');

  // you can also persist this path for the background isolate:
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('hivePath', hivePath);

  // REMOVED: OneSignal initialization - third-party data collection risk
  // Use Firebase Cloud Messaging instead for better App Store compliance

  // REMOVED: FlutterForegroundTask initialization - causes App Store rejection
  // Background services are not allowed in current App Store guidelines

  await Supabase.initialize(
    url: 'https://ojctqcthzuwrckvixbcd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY3RxY3RoenV3cmNrdml4YmNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3Mzk2MDgsImV4cCI6MjA3NTMxNTYwOH0.7eFKpZXGx5uhZwKbZnYVipKHZ5Xo3-0SGW__QVS5yJY',
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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.babyBlueCard,
          useMaterial3: true,
        ),
        onGenerateRoute: RouteGenerator.generateRoute,
        navigatorKey: navigatorKey,
        home: Consumer(
          builder: (context, ref, child) {
            return FutureBuilder<String?>(
              future: ref.watch(getIsLoggedInProvider.future),
              builder: (context, isLoggedInSnapshot) {
                if (isLoggedInSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final isLoggedIn = isLoggedInSnapshot.data ?? false;

                return FutureBuilder<String?>(
                  future: ref.watch(getIsOnboardingPassed.future),
                  builder: (context, isOnboardingSnapshot) {
                    if (isOnboardingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final isOnboardingPassed =
                        isOnboardingSnapshot.data ?? false;

                    return isLoggedIn == 'true'
                        ? const MainPage()
                        : isOnboardingPassed == 'true'
                            ? const LoginPage()
                            : OnboardingPage(onFinish: () async {
                                final secureStorage =
                                    ref.read(secureStorageServiceProvider);
                                await secureStorage.writeData(
                                    'isOnboardingPassed', 'true');
                                Navigator.pushNamed(context, '/login');
                              });
                  },
                );
              },
            );
          },
        ));
  }
}
