class RegisterPageModel {
  final bool isLoading;
  final String email;
  final String password;
  final String confirmPassword;
  final String emailError;
  final String passwordError;
  final String confirmPasswordError;

  RegisterPageModel({
    required this.isLoading,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.emailError,
    required this.passwordError,
    required this.confirmPasswordError,
  });

  RegisterPageModel.initial()
      : isLoading = false,
        email = '',
        password = '',
        confirmPassword = '',
        emailError = '',
        passwordError = '',
        confirmPasswordError = '';

  RegisterPageModel copyWith({
    bool? isLoading,
    String? email,
    String? password,
    String? confirmPassword,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
  }) {
    return RegisterPageModel(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      confirmPasswordError: confirmPasswordError ?? this.confirmPasswordError,
    );
  }
}
