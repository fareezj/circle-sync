import 'package:circle_sync/core/errors/failure.dart';
import 'package:circle_sync/features/map/data/datasources/map_services.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:circle_sync/features/map/domain/repositories/map_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapRepositoryProvider =
    Provider<MapRepository>((ref) => MapRepositoryImpl());

class MapRepositoryImpl implements MapRepository {
  @override
  Future<Either<Failure, List<PlacesModel>>> getPlaces(String circleId) async {
    try {
      final result = await MapServices().getPlaces(circleId);
      return Right(result);
    } catch (e) {
      return Left(ServerError(errorMessage: e));
    }
  }

  @override
  Future<Either<Failure, void>> insertPlace(PlacesModel place) async {
    try {
      final result = await MapServices().insertPlace(place);
      return Right(result);
    } catch (e) {
      return Left(ServerError(errorMessage: e));
    }
  }
}
