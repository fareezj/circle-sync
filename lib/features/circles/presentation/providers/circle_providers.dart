import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircleNotifier extends StateNotifier<CirclePageState> {
  Ref ref;
  CircleUsecase circleUsecase;
  CircleNotifier(this.ref, this.circleUsecase) : super(CirclePageState(false));

  Future<void> joinCircle() async {
    try {
      await circleUsecase.joinCircle('MULAN');
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
}

final circleNotifierProvider =
    StateNotifierProvider<CircleNotifier, CirclePageState>((ref) {
  return CircleNotifier(ref, ref.watch(circleUsecaseProvider));
});
