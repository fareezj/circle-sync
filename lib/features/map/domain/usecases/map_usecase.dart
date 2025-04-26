import 'package:circle_sync/core/errors/failure.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/data/repositories/map_repository_impl.dart';
import 'package:circle_sync/features/map/domain/repositories/map_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapUsecaseProvider =
    Provider<MapUsecase>((ref) => MapUsecase(ref.watch(mapRepositoryProvider)));

class MapUsecase {
  final MapRepository mapRepository;

  MapUsecase(this.mapRepository);

  Future<Either<Failure, List<PlacesModel>>> getPlaces(String circleId) async {
    return await mapRepository.getPlaces(circleId);
  }
}
