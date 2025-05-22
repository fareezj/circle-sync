import 'package:circle_sync/features/circles/data/models/circle_model.dart';
import 'package:circle_sync/features/circles/domain/usecases/circle_usecase.dart';
import 'package:circle_sync/features/map/presentation/routers/circle_navigation_router.dart';
import 'package:circle_sync/models/circle_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircleNotifier extends StateNotifier<CirclePageState> {
  Ref ref;
  CircleUsecase circleUsecase;
  CircleNotifier(this.ref, this.circleUsecase) : super(CirclePageState(false));

  Future<void> createCircle(
      WidgetRef ref, String circleName, Function() onSuccess) async {
    try {
      state = state.copyWith(isLoading: true);
      final result = await circleUsecase.createCircle(circleName);
      result.fold((_) {
        ref
            .read(globalMessageNotifier.notifier)
            .setMessage('Something went wrong, please try again later');
      }, (res) {
        ref.read(globalMessageNotifier.notifier).setMessage('Circle created!');
        onSuccess();
      });
    } catch (e) {
      throw Exception(e);
    } finally {
      state = state.copyWith(isLoading: false);
      circleSheetNavKey.currentState!.pop();
    }
  }

  Future<void> joinCircle(String code, Function() onSuccess) async {
    try {
      final result = await circleUsecase.joinCircle(code);
      result.fold((_) {
        ref
            .read(globalMessageNotifier.notifier)
            .setMessage('Something went wrong, please try again later');
      }, (res) {
        ref
            .read(globalMessageNotifier.notifier)
            .setMessage('New circle joined!');
        onSuccess();
      });
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
