import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapServices {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PlacesModel>> getPlaces(String circleId) async {
    try {
      print('🔍 Querying geofences table for circle_id: $circleId');

      // First, check if there are ANY geofences in the table
      final allGeofences = await _client.from('geofences').select();
      print('🌐 Total geofences in database: ${allGeofences.length}');
      if (allGeofences.isNotEmpty) {
        print('   Sample geofence: ${allGeofences.first}');
        final availableCircleIds =
            allGeofences.map((g) => g['circle_id']).toSet();
        print('   Available circle_ids: $availableCircleIds');
      }

      final resultList =
          await _client.from('geofences').select().eq('circle_id', circleId);
      print('🗃️ Raw database result for circle $circleId: $resultList');
      print('📊 Found ${resultList.length} geofences for this specific circle');

      final places =
          resultList.map((place) => PlacesModel.fromJson(place)).toList();
      print('✅ Converted to ${places.length} PlacesModel objects');

      return places;
    } catch (e) {
      print('❌ Error in getPlaces: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> insertPlace(PlacesModel place) async {
    try {
      final result = await _client.from('geofences').insert(place.toJson());
      print('INSERT RESULT: $result');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
