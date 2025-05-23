import 'package:circle_sync/features/authentication/data/models/register_model.dart';
import 'package:circle_sync/main.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/utils/field_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterNotifier extends StateNotifier<RegisterPageModel> {
  RegisterNotifier() : super(RegisterPageModel.initial());

  void updateName(String value) {
    final nameValid = FieldValidators().validateFullName(value);
    state = state.copyWith(
      name: value,
      nameError: nameValid ?? '',
    );
    _updateAllFieldPassed();
  }

  void updateEmail(String value) {
    final emailValid = FieldValidators().validateEmail(value);
    state = state.copyWith(
      email: value,
      emailError: emailValid ?? '',
    );
    _updateAllFieldPassed();
  }

  void updatePassword(String value) {
    final passwordValid = FieldValidators().validatePassword(value);
    state = state.copyWith(
      password: value,
      passwordError: passwordValid ? '' : 'Invalid password',
    );
    _updateAllFieldPassed();
  }

  void updateConfirmPassword(String value) {
    final isMatch = value == state.password;
    state = state.copyWith(
      confirmPassword: value,
      confirmPasswordError: isMatch ? '' : 'Passwords do not match',
    );
    _updateAllFieldPassed();
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
        'name': state.name,
      });

      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.writeData('email', state.email);
      await secureStorage.writeData('userId', userId);

      ref.read(globalMessageNotifier.notifier).setMessage(
          'Account created, please verify your email, before logging in');
      navigatorKey.currentState?.pop();
    } catch (e) {
      ref.read(errorMessageNotifier.notifier).setError(e.toString());
      throw Exception(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void _updateAllFieldPassed() {
    final allFieldsValid = state.nameError.isEmpty &&
        state.emailError.isEmpty &&
        state.passwordError.isEmpty &&
        state.confirmPasswordError.isEmpty &&
        state.name.isNotEmpty &&
        state.email.isNotEmpty &&
        state.password.isNotEmpty &&
        state.confirmPassword.isNotEmpty;

    state = state.copyWith(allFieldPassed: allFieldsValid);
  }
}

final registerNotifierProvider =
    StateNotifierProvider<RegisterNotifier, RegisterPageModel>((ref) {
  return RegisterNotifier();
});
