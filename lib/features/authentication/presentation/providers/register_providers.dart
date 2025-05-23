import 'package:circle_sync/features/authentication/data/models/register_model.dart';
import 'package:circle_sync/main.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/route_generator.dart';
import 'package:circle_sync/utils/field_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterNotifier extends StateNotifier<RegisterPageModel> {
  RegisterNotifier() : super(RegisterPageModel.initial());

  void updateEmail(String value) {
    final emailValid = FieldValidators().validateEmail(value);
    state = state.copyWith(
      email: value,
      emailError: emailValid ?? '',
    );
  }

  void updatePassword(String value) {
    final passwordValid = FieldValidators().validatePassword(value);
    state = state.copyWith(
      password: value,
      passwordError: passwordValid ? '' : 'Invalid password',
    );
  }

  void updateConfirmPassword(String value) {
    final isMatch = value == state.password;
    state = state.copyWith(
      confirmPassword: value,
      confirmPasswordError: isMatch ? '' : 'Passwords do not match',
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordObscure: !state.isPasswordObscure);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
        isConfirmPasswordObscure: !state.isConfirmPasswordObscure);
  }

  Future<void> onRegister(WidgetRef ref) async {
    try {
      state = state.copyWith(isLoading: true);
      final supabase = Supabase.instance.client;

      final res = await supabase.auth.signUp(
        email: state.email,
        password: state.password,
      );

      final userId = res.user!.id;
      await supabase.from('users').insert({
        'user_id': userId,
        'email': state.email,
        'name': state.email,
      });

      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.writeData('isLoggedIn', 'true');
      await secureStorage.writeData('email', state.email);
      await secureStorage.writeData('userId', userId);

      navigatorKey.currentState?.pushReplacementNamed(RouteGenerator.mainPage);
    } catch (e) {
      ref.read(errorMessageNotifier.notifier).setError(e.toString());
      throw Exception(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final registerNotifierProvider =
    StateNotifierProvider<RegisterNotifier, RegisterPageModel>((ref) {
  return RegisterNotifier();
});
