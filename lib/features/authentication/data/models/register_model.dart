class RegisterPageModel {
  final bool isLoading;
  final bool isPasswordObscure;
  final bool isConfirmPasswordObscure;
  final bool allFieldPassed;
  final String email;
  final String name;
  final String password;
  final String confirmPassword;
  final String nameError;
  final String emailError;
  final String passwordError;
  final String confirmPasswordError;

  RegisterPageModel({
    required this.isLoading,
    required this.isPasswordObscure,
    required this.isConfirmPasswordObscure,
    required this.allFieldPassed,
    required this.email,
    required this.name,
    required this.password,
    required this.confirmPassword,
    required this.nameError,
    required this.emailError,
    required this.passwordError,
    required this.confirmPasswordError,
  });

  RegisterPageModel.initial()
      : isLoading = false,
        isPasswordObscure = true,
        isConfirmPasswordObscure = true,
        allFieldPassed = false,
        email = '',
        name = '',
        password = '',
        confirmPassword = '',
        nameError = '',
        emailError = '',
        passwordError = '',
        confirmPasswordError = '';

  RegisterPageModel copyWith({
    bool? isLoading,
    bool? isPasswordObscure,
    bool? isConfirmPasswordObscure,
    bool? allFieldPassed,
    String? email,
    String? name,
    String? password,
    String? confirmPassword,
    String? nameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
  }) {
    return RegisterPageModel(
      isLoading: isLoading ?? this.isLoading,
      isPasswordObscure: isPasswordObscure ?? this.isPasswordObscure,
      isConfirmPasswordObscure:
          isConfirmPasswordObscure ?? this.isConfirmPasswordObscure,
      allFieldPassed: allFieldPassed ?? this.allFieldPassed,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      nameError: nameError ?? this.nameError,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      confirmPasswordError: confirmPasswordError ?? this.confirmPasswordError,
    );
  }
}
