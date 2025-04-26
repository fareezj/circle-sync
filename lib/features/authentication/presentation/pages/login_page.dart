import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
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
  bool _isLoading = false;

  SupabaseClient get supabase => Supabase.instance.client;

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1) Sign in via Supabase Auth
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // if (res.error != null || res.user == null) {
    //   setState(() {
    //     _errorMessage = res.error?.message ?? 'Login failed';
    //     _isLoading = false;
    //   });
    //   return;
    // }

    final userId = res.user!.id;

    // 2) Retrieve OneSignal player ID (device ID)
    //final status   = await OneSignal.Notifications.
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null) {
      // 3) Update `users` table with this OneSignal ID
      final updateRes = await supabase
          .from('users')
          .update({'onesignal_id': playerId})
          .eq('user_id', userId)
          .select(); // optional: return the updated row

      // if (updateRes.error != null) {
      //   // non‑fatal: just log it
      //   print('Failed to update OneSignal ID: ${updateRes.error!.message}');
      // }
    }

    // 4) Persist login flag in secure storage
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.writeData('isLoggedIn', 'true');

    // 5) Navigate to main page
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, RouteGenerator.mainPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Login'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, RouteGenerator.registerPage),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Register'),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
