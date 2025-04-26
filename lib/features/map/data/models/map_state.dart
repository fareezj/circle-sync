import 'package:circle_sync/features/map/data/models/map_models.dart';

class MapPageState {
  final List<PlacesModel> placeList;
  final bool isLoading;

  MapPageState({
    required this.isLoading,
    required this.placeList,
  });

  MapPageState copyWith({
    List<PlacesModel>? placeList,
    bool? isLoading,
  }) {
    return MapPageState(
      isLoading: isLoading ?? this.isLoading,
      placeList: placeList ?? this.placeList,
    );
  }
}
