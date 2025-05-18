import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:background_location_tracker/background_location_tracker.dart';
import 'package:circle_sync/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
void backgroundCallback() {
  BackgroundLocationTrackerManager.handleBackgroundUpdated((data) async {
    final prefs = await SharedPreferences.getInstance();
    final circleId = prefs.getString('bg_circle_id')!;
    final userId = prefs.getString('bg_user_id')!;
    Repo().update(
      data,
      circleId: circleId,
      userId: userId,
      loc: LatLng(data.lat, data.lon),
    );
  });
}

@override
class BgLocationPage extends StatefulWidget {
  const BgLocationPage({super.key});

  @override
  BgLocationPageState createState() => BgLocationPageState();
}

class BgLocationPageState extends State<BgLocationPage> {
  var isTracking = false;

  Timer? _timer;
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _initApp();
    _getTrackingStatus();
    _startLocationsUpdatesStream();
  }

  _initApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await BackgroundLocationTrackerManager.initialize(
      backgroundCallback,
      config: const BackgroundLocationTrackerConfig(
        loggingEnabled: true,
        androidConfig: AndroidConfig(
          notificationIcon: 'explore',
          trackingInterval: Duration(seconds: 4),
          distanceFilterMeters: null,
        ),
        iOSConfig: IOSConfig(
          activityType: ActivityType.FITNESS,
          distanceFilterMeters: null,
          restartAfterKill: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    MaterialButton(
                      onPressed: _requestLocationPermission,
                      child: const Text('Request location permission'),
                    ),
                    if (Platform.isAndroid) ...[
                      const Text(
                          'Permission on android is only needed starting from sdk 33.'),
                    ],
                    MaterialButton(
                      onPressed: _requestNotificationPermission,
                      child: const Text('Request Notification permission'),
                    ),
                    MaterialButton(
                      child: const Text('Send notification'),
                      onPressed: () =>
                          sendNotification('Hello from another world'),
                    ),
                    MaterialButton(
                      onPressed: isTracking
                          ? null
                          : () async {
                              await BackgroundLocationTrackerManager
                                  .startTracking();
                              setState(() => isTracking = true);
                            },
                      child: const Text('Start Tracking'),
                    ),
                    MaterialButton(
                      onPressed: isTracking
                          ? () async {
                              await LocationDao().clear();
                              await _getLocations();
                              await BackgroundLocationTrackerManager
                                  .stopTracking();
                              setState(() => isTracking = false);
                            }
                          : null,
                      child: const Text('Stop Tracking'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.black12,
                height: 2,
              ),
              const Text('Locations'),
              MaterialButton(
                onPressed: _getLocations,
                child: const Text('Refresh locations'),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_locations.isEmpty) {
                      return const Text('No locations saved');
                    }
                    return ListView.builder(
                      itemCount: _locations.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          _locations[index],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getTrackingStatus() async {
    isTracking = await BackgroundLocationTrackerManager.isTracking();
    setState(() {});
  }

  Future<void> _requestLocationPermission() async {
    final result = await Permission.location.request();
    if (result == PermissionStatus.granted) {
      print('GRANTED'); // ignore: avoid_print
    } else {
      print('NOT GRANTED'); // ignore: avoid_print
    }
  }

  Future<void> _requestNotificationPermission() async {
    final result = await Permission.notification.request();
    if (result == PermissionStatus.granted) {
      print('GRANTED'); // ignore: avoid_print
    } else {
      print('NOT GRANTED'); // ignore: avoid_print
    }
  }

  Future<void> _getLocations() async {
    final locations = await LocationDao().getLocations();
    setState(() {
      _locations = locations;
    });
  }

  void _startLocationsUpdatesStream() {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(milliseconds: 250), (timer) => _getLocations());
  }
}

class Repo {
  static Repo? _instance;

  Repo._();

  factory Repo() => _instance ??= Repo._();

  Future<void> update(
    BackgroundLocationUpdateData data, {
    required String circleId,
    required String userId,
    required LatLng loc,
  }) async {
    final text = 'Location Update: Lat: ${data.lat} Lon: ${data.lon}';
    print(text); // ignore: avoid_print
    //sendNotification(text);
    print('awow');

    await Supabase.initialize(
      url: 'https://hnbqegfgzwugkdtfysma.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuYnFlZ2Znend1Z2tkdGZ5c21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTE2NjQsImV4cCI6MjA2MDcyNzY2NH0.l_RqDcUmqvB_MRJ3VG-VQJcjVXqlKeQPghoEy5awTGc',
    );
    //LocationService().upsertLocation(circleId, userId, loc, false);
    await simulateMovement(userId: userId, circleId: circleId);

    await LocationDao().saveLocation(data);
  }
}

Future<void> simulateMovement({
  required String userId,
  required String circleId,
  Duration stepDelay = const Duration(seconds: 5),
}) async {
  final svc = LocationService();
  // usage:
  final points = <LatLng>[
    LatLng(3.0620, 99.6721),
    LatLng(4.0619, 98.6609),
    LatLng(5.0657, 97.6629),
    // …etc
  ];
  for (final p in points) {
    await svc.upsertLocation(circleId, userId, p, false);
    await Future.delayed(stepDelay);
  }
}

class LocationDao {
  static const _locationsKey = 'background_updated_locations';
  static const _locationSeparator = '-/-/-/';

  static LocationDao? _instance;

  LocationDao._();

  factory LocationDao() => _instance ??= LocationDao._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveLocation(BackgroundLocationUpdateData data) async {
    final locations = await getLocations();

    locations.add(
        '${DateTime.now().toIso8601String()}       ${data.lat},${data.lon}');

    await (await prefs)
        .setString(_locationsKey, locations.join(_locationSeparator));
  }

  Future<List<String>> getLocations() async {
    final prefs = await this.prefs;
    await prefs.reload();
    final locationsString = prefs.getString(_locationsKey);
    if (locationsString == null) return [];
    return locationsString.split(_locationSeparator);
  }

  Future<void> clear() async => (await prefs).clear();
}

void sendNotification(String text) {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('app_icon'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  FlutterLocalNotificationsPlugin().initialize(settings);
  FlutterLocalNotificationsPlugin().show(
    Random().nextInt(9999),
    'Title',
    text,
    const NotificationDetails(
      android: AndroidNotificationDetails('test_notification', 'Test'),
      iOS: DarwinNotificationDetails(),
    ),
  );
}
