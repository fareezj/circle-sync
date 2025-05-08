import 'package:circle_sync/core/errors/failure.dart';
import 'package:dartz/dartz.dart';

abstract class CircleRepository {
  Future<Either<Failure, void>> joinCircle(String code);
  Future<Either<Failure, void>> getCircleMembers(String circleId);
}
