import 'package:circle_sync/core/errors/failure.dart';
import 'package:circle_sync/features/map/data/models/map_models.dart';
import 'package:dartz/dartz.dart';

abstract class MapRepository {
  Future<Either<Failure, List<PlacesModel>>> getPlaces(String circleId);
}
