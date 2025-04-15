import 'package:circle_sync/providers/app_configs/app_configs_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../route_generator.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await secureStorage.writeData('isLoggedIn', 'true');
      Navigator.pushReplacementNamed(context, RouteGenerator.mainPage);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              if (_isLoading) ...[
                CircularProgressIndicator(),
              ] else ...[
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, RouteGenerator.registerPage),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text('Register'),
                ),
              ],
              if (_errorMessage != null) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
