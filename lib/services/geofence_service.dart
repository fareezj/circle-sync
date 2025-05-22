import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabase = Supabase.instance.client;

Future<void> initGeofence(WidgetRef ref) async {
  print('===INIT GEOFENCE===');
  final userId = await ref.watch(getUserIdProvider.future);

  // 1) Initialise the native geofence plugin
  await NativeGeofenceManager.instance.initialize();

  // 2) Bail out early if we've already registered these once
  final prefs = await SharedPreferences.getInstance();
  final key = 'geofences_registered_$userId';
  if (prefs.getBool(key) == true) {
    print('🗺️ Geofences already registered for $userId, skipping.');
    return;
  }

  // 3) Fetch your zones from Supabase
  final resp = await supabase.from('geofences').select('''
      title,
      radius_m,
      center_geography
    ''');

  // if (resp != null) {
  //   print('❌ Supabase error: ${resp!.message}');
  //   return;
  // }

  final rows = resp as List<dynamic>;

  print('FETCHED GEOFENCES');
  print(rows.toString());

  // 4) Register each zone
  for (var row in rows) {
    final wkt = row['center_geography'] as String;
    // e.g. "POINT(3.0620 101.6721)"
    final inside = wkt.replaceAll(RegExp(r'POINT\(|\)'), '');
    final parts = inside.split(RegExp(r'\s+'));
    final lat = double.parse(parts[0]);
    final lon = double.parse(parts[1]);
    final radius = (row['radius_m'] as num).toDouble();
    final title = row['title'] as String;

    final fence = Geofence(
      id: '${title.replaceAll(" ", "_")}|$userId',
      location: Location(latitude: lat, longitude: lon),
      radiusMeters: radius,
      triggers: {
        GeofenceEvent.enter,
        GeofenceEvent.exit,
        GeofenceEvent.dwell,
      },
      iosSettings: const IosGeofenceSettings(
        initialTrigger: true,
      ),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: {GeofenceEvent.enter, GeofenceEvent.dwell},
        expiration: Duration(days: 7),
        loiteringDelay: Duration(minutes: 5),
        notificationResponsiveness: Duration(minutes: 5),
      ),
    );

    await NativeGeofenceManager.instance
        .createGeofence(fence, geofenceTriggered);
    print('➡️ Registered geofence: $title');
  }

  // 5) Mark as done so we don’t re-add next time
  await prefs.setBool(key, true);

  // 6) Verify
  final active = await NativeGeofenceManager.instance.getRegisteredGeofences();
  print('✅ Total active geofences: ${active.length}');
}

@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  debugPrint('Geofence triggered with params11: $params');

  try {
    final parts = params.geofences[0].id.split('|');
    final id = parts[0];
    final userId = parts[1];
    // 2. (Android) promote to foreground so the OS won't kill your isolate mid-network :contentReference[oaicite:1]{index=1}
    NativeGeofenceBackgroundManager.instance.promoteToForeground();

    // 1. Create a lightweight client—this works in any isolate :contentReference[oaicite:2]{index=2}
    final supabase = SupabaseClient(
      'https://hnbqegfgzwugkdtfysma.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhuYnFlZ2Znend1Z2tkdGZ5c21hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTE2NjQsImV4cCI6MjA2MDcyNzY2NH0.l_RqDcUmqvB_MRJ3VG-VQJcjVXqlKeQPghoEy5awTGc',
    );
    // Fetch circle IDs
    final res = await supabase.from('circles').select('circle_id');
    print(params);
    print(params.location);
    print(res);

    final circleIds = res.map((r) => r['circle_id'] as String).toList();

    // Upsert your location for each circle
    final lat = params.geofences[0].location.latitude;
    final lng = params.geofences[0].location.longitude;
    print('lat: $lat');
    print('lng: $lng');
    for (final circleId in circleIds) {
      await supabase.from('locations').upsert(
        {
          'circle_id': circleId,
          'user_id': userId,
          'lat': lat,
          'lng': lng,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'is_paused': false,
        },
        onConflict: 'circle_id,user_id',
      ); // atomic update/insert :contentReference[oaicite:5]{index=5});
    }

    // 2. Demote back to background when you’re done :contentReference[oaicite:3]{index=3}
    NativeGeofenceBackgroundManager.instance.demoteToBackground();
  } catch (error, stack) {
    debugPrint('❌ geofenceTriggered error: $error');
    debugPrint('$stack');
  }
}
