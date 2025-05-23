import 'package:circle_sync/features/authentication/presentation/providers/login_providers.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:circle_sync/widgets/confirm_button.dart';
import 'package:circle_sync/widgets/custom_input.dart';
import 'package:circle_sync/widgets/global_message.dart';
import 'package:circle_sync/widgets/loading_indicator.dart';
import 'package:circle_sync/widgets/message_overlay.dart';
import 'package:circle_sync/widgets/text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../route_generator.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  final bool _isLoading = false;

  SupabaseClient get supabase => Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginNotifierProvider).isLoading;
    final formState = ref.watch(loginNotifierProvider);
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
                    TextWidgets.mainBold(title: 'Login', fontSize: 38),
                    const SizedBox(height: 40),
                    CustomInputWidget(
                      title: 'Email',
                      isMandatory: false,
                      hintText: '',
                      isError: formState.emailError.isNotEmpty,
                      errorMessage: formState.emailError,
                      onChanged: (value) => ref
                          .read(loginNotifierProvider.notifier)
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
                          .read(loginNotifierProvider.notifier)
                          .togglePasswordVisibility(),
                      onChanged: (value) => ref
                          .read(loginNotifierProvider.notifier)
                          .updatePassword(value),
                    ),
                    const SizedBox(height: 50),
                    ConfirmButton(
                      onClick: () =>
                          ref.read(loginNotifierProvider.notifier).onLogin(ref),
                      title: 'Login',
                    ),
                    const SizedBox(height: 20),
                    ConfirmButton(
                      onClick: () => Navigator.pushNamed(
                          context, RouteGenerator.registerPage),
                      title: 'Register',
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
          if (isLoading) LoadingIndicator()
        ],
      ),
    );
  }
}
