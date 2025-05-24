import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabase = Supabase.instance.client;

Future<void> initGeofence(WidgetRef ref) async {
  print('=== INIT GEOFENCE ===');
  final userId = await ref.watch(getUserIdProvider.future);

  // 1) Initialise the native geofence plugin
  final manager = NativeGeofenceManager.instance;
  await manager.initialize();

  // 2) Pull existing geofence IDs so we only add the missing ones
  final existingIds =
      (await manager.getRegisteredGeofences()).map((g) => g.id).toSet();

  // 3) Fetch your zones from Supabase
  final resp = await supabase.from('geofences').select('''
    title,
    radius_m,
    center_geography
  ''');
  final rows = resp as List<dynamic>;

  print('FETCHED GEOFENCES: ${rows.length} rows');

  // 4) Register each zone if not already present
  for (var row in rows) {
    final title = row['title'] as String;
    final id = '${title.replaceAll(" ", "_")}|$userId';

    if (existingIds.contains(id)) {
      print('⚡ Already registered: $title');
      continue;
    }

    // parse WKT "POINT(lat lon)"
    final wkt = row['center_geography'] as String;
    final coords = wkt
        .replaceAll(RegExp(r'POINT\(|\)'), '')
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList();
    final lat = coords[0], lon = coords[1];
    final radius = (row['radius_m'] as num).toDouble();

    final fence = Geofence(
      id: id,
      location: Location(latitude: lat, longitude: lon),
      radiusMeters: radius,
      triggers: {
        GeofenceEvent.enter,
        GeofenceEvent.exit,
        GeofenceEvent.dwell,
      },
      iosSettings: const IosGeofenceSettings(initialTrigger: true),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: {GeofenceEvent.enter, GeofenceEvent.dwell},
        expiration: Duration(days: 7),
        loiteringDelay: Duration(minutes: 5),
        notificationResponsiveness: Duration(minutes: 5),
      ),
    );

    await manager.createGeofence(fence, geofenceTriggered);
    print('➡️ Registered new geofence: $title');
  }

  // 5) Verify total active
  final active = await manager.getRegisteredGeofences();
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
