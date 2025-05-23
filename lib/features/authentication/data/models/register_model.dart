class RegisterPageModel {
  final bool isLoading;
  final bool isPasswordObscure;
  final bool isConfirmPasswordObscure;
  final String email;
  final String password;
  final String confirmPassword;
  final String emailError;
  final String passwordError;
  final String confirmPasswordError;

  RegisterPageModel({
    required this.isLoading,
    required this.isPasswordObscure,
    required this.isConfirmPasswordObscure,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.emailError,
    required this.passwordError,
    required this.confirmPasswordError,
  });

  RegisterPageModel.initial()
      : isLoading = false,
        isPasswordObscure = true,
        isConfirmPasswordObscure = true,
        email = '',
        password = '',
        confirmPassword = '',
        emailError = '',
        passwordError = '',
        confirmPasswordError = '';

  RegisterPageModel copyWith({
    bool? isLoading,
    bool? isPasswordObscure,
    bool? isConfirmPasswordObscure,
    String? email,
    String? password,
    String? confirmPassword,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
  }) {
    return RegisterPageModel(
      isLoading: isLoading ?? this.isLoading,
      isPasswordObscure: isPasswordObscure ?? this.isPasswordObscure,
      isConfirmPasswordObscure:
          isConfirmPasswordObscure ?? this.isConfirmPasswordObscure,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      confirmPasswordError: confirmPasswordError ?? this.confirmPasswordError,
    );
  }
}
