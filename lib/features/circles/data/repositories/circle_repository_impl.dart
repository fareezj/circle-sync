import 'package:circle_sync/core/errors/failure.dart';
import 'package:circle_sync/features/circles/data/datasources/circle_service.dart';
import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/repositories/circle_repository.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final circleRepositoryProvider =
    Provider<CircleRepository>((ref) => CircleRepositoryImpl());

class CircleRepositoryImpl implements CircleRepository {
  @override
  Future<Either<Failure, void>> joinCircle(String code) async {
    try {
      final result = CircleService().joinCircle(code);
      return Right(result);
    } catch (e) {
      return Left(ServerError(errorMessage: e));
    }
  }

  @override
  Future<Either<Failure, List<CircleMembersModel>>> getCircleMembers(
      String circleId) async {
    try {
      final result = await CircleService().getCircleMembers(circleId);
      return Right(result);
    } catch (e) {
      return Left(ServerError(errorMessage: e));
    }
  }

  @override
  Future<Either<Failure, List<CircleModel>>> getJoinedCircles() async {
    try {
      final result = await CircleService().getJoinedCircles();
      return Right(result);
    } catch (e) {
      return Left(ServerError(errorMessage: e));
    }
  }

  @override
  Future<Either<Failure, void>> createCircle(String circleName) async {
    try {
      final result = await CircleService().createCircle(circleName);
      return Right(result);
    } catch (e) {
      return Left(ServerError(errorMessage: e));
    }
  }
}
