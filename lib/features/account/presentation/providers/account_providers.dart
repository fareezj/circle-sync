import 'package:circle_sync/features/account/data/models/account_model.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountNotifier extends StateNotifier<AccountPageModel> {
  final Ref ref;
  AccountNotifier(this.ref) : super(AccountPageModel.initial());

  Future<void> loadAccountDetails() async {
    try {
      state = state.copyWith(isLoading: true);
      final email = await ref.read(getEmailProvider.future);
      final name = await ref.read(getUsernameProvider.future);
      state = state.copyWith(email: email, name: name, isLoading: false);
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final accountNotifierProvider =
    StateNotifierProvider<AccountNotifier, AccountPageModel>((ref) {
  return AccountNotifier(ref);
});
