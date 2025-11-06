import 'package:circle_sync/core/errors/failure.dart';
import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

abstract class CircleRepository {
  Future<Either<Failure, void>> createCircle(String name, BuildContext context);
  Future<Either<Failure, void>> joinCircle(String code, BuildContext context);
  Future<Either<Failure, List<CircleMembersModel>>> getCircleMembers(
      String circleId);
  Future<Either<Failure, List<CircleModel>>> getJoinedCircles();
}
