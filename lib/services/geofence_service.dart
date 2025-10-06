import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/// Initializes geofences for a specific circle based on its ID.
///
/// - Filters Supabase records by `circle_id`.
/// - Uses the DB `id` field as the native geofence ID for consistency.
/// - Ensures no duplicate registrations.
Future<void> initGeofence({
  required WidgetRef ref,
  required String circleId,
}) async {
  print('=== INIT GEOFENCE for Circle: $circleId ===');

  // 1️⃣ Initialize the native geofence plugin
  final manager = NativeGeofenceManager.instance;
  await manager.initialize();

  // 2️⃣ Get already-registered geofence IDs
  final existingIds =
      (await manager.getRegisteredGeofences()).map((g) => g.id).toSet();

  // 3️⃣ Fetch geofences for this circle from Supabase
  final response = await Supabase.instance.client
      .from('geofences')
      .select('geofence_id, title, radius_m, center_geography')
      .eq('circle_id', circleId);

  final rows = (response as List<dynamic>);
  print('Fetched ${rows.length} geofences for circle $circleId');

  // 4️⃣ Register missing geofences
  for (final row in rows) {
    final geoId = row['geofence_id'] as String;
    final title = row['title'] as String;
    if (existingIds.contains(geoId)) {
      print('⚡ Geo "$title" ($geoId) already registered');
      continue;
    }

    // Parse WKT "POINT(lat lon)"
    final wkt = row['center_geography'] as String;
    final coords = wkt
        .replaceAll(RegExp(r'POINT\(|\)'), '')
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList();
    final lat = coords[0];
    final lon = coords[1];
    final radius = (row['radius_m'] as num).toDouble();

    final fence = Geofence(
      id: geoId,
      // Use precise Location object
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

    // 5️⃣ Create and register the geofence
    await manager.createGeofence(fence, geofenceTriggered);
    print('➡️ Registered new geofence: $title ($geoId)');
  }

  // 6️⃣ Log total active
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
    await Supabase.initialize(
      url: 'https://ojctqcthzuwrckvixbcd.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qY3RxY3RoenV3cmNrdml4YmNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3Mzk2MDgsImV4cCI6MjA3NTMxNTYwOH0.7eFKpZXGx5uhZwKbZnYVipKHZ5Xo3-0SGW__QVS5yJY',
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
