import 'package:circle_sync/features/authentication/presentation/providers/register_providers.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/widgets/confirm_button.dart';
import 'package:circle_sync/widgets/custom_input.dart';
import 'package:circle_sync/widgets/global_message.dart';
import 'package:circle_sync/widgets/loading_indicator.dart';
import 'package:circle_sync/widgets/message_overlay.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../route_generator.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(registerNotifierProvider).isLoading;
    final formState = ref.watch(registerNotifierProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    TextWidgets.mainBold(title: 'Register', fontSize: 38),
                    const SizedBox(height: 40),
                    CustomInputWidget(
                      title: 'Name',
                      isMandatory: false,
                      hintText: '',
                      isError: formState.nameError.isNotEmpty,
                      errorMessage: formState.nameError,
                      onChanged: (value) => ref
                          .read(registerNotifierProvider.notifier)
                          .updateName(value),
                    ),
                    const SizedBox(height: 20),
                    CustomInputWidget(
                      title: 'Email',
                      isMandatory: false,
                      hintText: '',
                      isError: formState.emailError.isNotEmpty,
                      errorMessage: formState.emailError,
                      onChanged: (value) => ref
                          .read(registerNotifierProvider.notifier)
                          .updateEmail(value),
                    ),
                    const SizedBox(height: 20),
                    CustomInputWidget(
                      title: 'Password',
                      isMandatory: false,
                      hintText: '',
                      isPassword: true,
                      isError: formState.passwordError.isNotEmpty,
                      errorMessage: formState.passwordError,
                      isObscure: formState.isPasswordObscure,
                      onSetObscure: () => ref
                          .read(registerNotifierProvider.notifier)
                          .togglePasswordVisibility(),
                      onChanged: (value) => ref
                          .read(registerNotifierProvider.notifier)
                          .updatePassword(value),
                    ),
                    const SizedBox(height: 20),
                    CustomInputWidget(
                      title: 'Confirm Password',
                      isMandatory: false,
                      hintText: '',
                      isPassword: true,
                      isError: formState.confirmPasswordError.isNotEmpty,
                      errorMessage: formState.confirmPasswordError,
                      isObscure: formState.isConfirmPasswordObscure,
                      onSetObscure: () => ref
                          .read(registerNotifierProvider.notifier)
                          .toggleConfirmPasswordVisibility(),
                      onChanged: (value) => ref
                          .read(registerNotifierProvider.notifier)
                          .updateConfirmPassword(value),
                    ),
                    const SizedBox(height: 50),
                    ConfirmButton(
                      isEnabled: formState.allFieldPassed,
                      onClick: () => ref
                          .read(registerNotifierProvider.notifier)
                          .onRegister(ref),
                      title: 'Register',
                    ),
                    const SizedBox(height: 20),
                    ConfirmButton(
                      onClick: () => Navigator.pushNamed(
                          context, RouteGenerator.loginPage),
                      title: 'Login',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: MessageOverlay(
              messageProvider: errorMessageNotifier,
              messageType: MessageType.failed,
            ),
          ),
          SafeArea(
            child: MessageOverlay(
              messageProvider: globalMessageNotifier,
              messageType: MessageType.info,
            ),
          ),
          if (isLoading) LoadingIndicator()
        ],
      ),
    );
  }
}
