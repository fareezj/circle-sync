import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapServices {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PlacesModel>> getPlaces(String circleId) async {
    try {
      final resultList =
          await _client.from('geofences').select().eq('circle_id', circleId);
      return resultList.map((place) => PlacesModel.fromJson(place)).toList();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> insertPlace(PlacesModel place) async {
    try {
      final result = await _client.from('geofences').insert(place.toJson());
      print('INSERT RESULT: $result');
    } catch (e) {
      throw Exception(e);
    }
  }
}
