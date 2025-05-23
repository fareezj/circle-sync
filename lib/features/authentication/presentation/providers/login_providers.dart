import 'package:circle_sync/features/authentication/data/models/login_model.dart';
import 'package:circle_sync/main.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/route_generator.dart';
import 'package:circle_sync/utils/field_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginNotifer extends StateNotifier<LoginPageModel> {
  LoginNotifer() : super(LoginPageModel.initial());

  void updateEmail(String value) {
    final emailValid = FieldValidators().validateEmail(value);
    state = state.copyWith(
      email: value,
      emailError: emailValid ?? '',
      allFieldPassed: emailValid == null &&
          FieldValidators().validatePassword(state.password),
    );
  }

  void updatePassword(String value) {
    final passwordValid = FieldValidators().validatePassword(value);
    state = state.copyWith(
      password: value,
      passwordError: passwordValid ? '' : 'Invalid password',
      allFieldPassed:
          passwordValid && FieldValidators().validateEmail(state.email) == null,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordObscure: !state.isPasswordObscure);
  }

  Future<void> onLogin(WidgetRef ref) async {
    try {
      state = state.copyWith(isLoading: true);
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signInWithPassword(
        email: state.email,
        password: state.password,
      );

      final userId = res.user!.id;
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null) {
        final updateRes = await supabase
            .from('users')
            .update({'onesignal_id': playerId})
            .eq('user_id', userId)
            .select();

        final secureStorage = ref.read(secureStorageServiceProvider);
        await secureStorage.writeData('isLoggedIn', 'true');
        await secureStorage.writeData('name', updateRes[0]['name']);
        await secureStorage.writeData('email', state.email);
        await secureStorage.writeData('userId', userId);
        await secureStorage.writeData('onesignalId', playerId);
      }
      navigatorKey.currentState?.pushReplacementNamed(RouteGenerator.mainPage);
    } catch (e) {
      ref.read(errorMessageNotifier.notifier).setError(e.toString());
      throw Exception(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final loginNotifierProvider =
    StateNotifierProvider<LoginNotifer, LoginPageModel>((ref) {
  return LoginNotifer();
});
