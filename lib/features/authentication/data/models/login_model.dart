class LoginPageModel {
  final bool isLoading;
  final String email;
  final String password;
  final String emailError;
  final String passwordError;
  final bool allFieldPassed;
  final bool isPasswordObscure;

  LoginPageModel({
    required this.isLoading,
    required this.email,
    required this.password,
    required this.emailError,
    required this.passwordError,
    required this.allFieldPassed,
    required this.isPasswordObscure,
  });

  /// Named constructor to initialize default values
  LoginPageModel.initial()
      : isLoading = false,
        email = '',
        password = '',
        emailError = '',
        passwordError = '',
        allFieldPassed = false,
        isPasswordObscure = true;

  /// Creates a copy of the current instance with updated values
  LoginPageModel copyWith({
    bool? isLoading,
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
    bool? allFieldPassed,
    bool? isPasswordObscure,
  }) {
    return LoginPageModel(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      allFieldPassed: allFieldPassed ?? this.allFieldPassed,
      isPasswordObscure: isPasswordObscure ?? this.isPasswordObscure,
    );
  }
}
