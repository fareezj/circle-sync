import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/data/models/map_state.dart';
import 'package:circle_sync/features/map/domain/usecases/map_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapNotifier extends StateNotifier<MapPageState> {
  final Ref ref;
  final MapUsecase mapUsecase;
  MapNotifier(this.mapUsecase, this.ref)
      : super(MapPageState(isLoading: false, placeList: []));

  Future<void> getPlaces(String circleId) async {
    try {
      final result = await mapUsecase.getPlaces(circleId);
      result.fold((_) {}, (list) {
        state = state.copyWith(placeList: list);
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> insertPlace(PlacesModel place) async {
    try {
      print(place.toJson());
      final result = await mapUsecase.insertPlace(place);
      result.fold((_) {}, (list) {
        print('INSERT SUCCESS!');
      });
    } catch (e) {
      throw Exception(e);
    }
  }
}

final mapNotiferProvider =
    StateNotifierProvider<MapNotifier, MapPageState>((ref) {
  return MapNotifier(ref.watch(mapUsecaseProvider), ref);
});
