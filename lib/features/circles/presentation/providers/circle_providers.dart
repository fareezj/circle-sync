import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircleNotifier extends StateNotifier<CirclePageState> {
  Ref ref;
  CircleUsecase circleUsecase;
  CircleNotifier(this.ref, this.circleUsecase) : super(CirclePageState(false));

  Future<void> createCircle(String circleName) async {
    try {
      await circleUsecase.createCircle(circleName);
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> joinCircle() async {
    try {
      await circleUsecase.joinCircle('Y7FC');
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> getCircleMembers() async {
    try {
      await circleUsecase
          .getCircleMembers('82028251-33ed-4360-b366-9027c824c096');
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<List<CircleModel>> getJoinedCircles() async {
    try {
      List<CircleModel> circleList = [];
      final result = await circleUsecase.getJoinedCircles();
      result.fold((_) {}, (res) => circleList = res);
      return circleList;
    } catch (e) {
      throw Exception(e);
    }
  }
}

final circleNotifierProvider =
    StateNotifierProvider<CircleNotifier, CirclePageState>((ref) {
  return CircleNotifier(ref, ref.watch(circleUsecaseProvider));
});
