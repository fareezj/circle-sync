import 'package:circle_sync/core/errors/failure.dart';
import 'package:circle_sync/features/circles/data/repositories/circle_repository_impl.dart';
import 'package:circle_sync/features/circles/domain/repositories/circle_repository.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final circleUsecaseProvider =
    Provider((ref) => CircleUsecase(ref.watch(circleRepositoryProvider)));

class CircleUsecase {
  CircleRepository circleRepository;
  CircleUsecase(this.circleRepository);

  Future<Either<Failure, void>> createCircle(String circleName) async {
    return circleRepository.createCircle(circleName);
  }

  Future<Either<Failure, void>> joinCircle(String code) async {
    return circleRepository.joinCircle(code);
  }

  Future<Either<Failure, void>> getCircleMembers(String circleId) async {
    return circleRepository.getCircleMembers(circleId);
  }

  Future<Either<Failure, List<CircleModel>>> getJoinedCircles() async {
    return circleRepository.getJoinedCircles();
  }
}
