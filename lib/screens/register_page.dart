import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  SupabaseClient get supabase => Supabase.instance.client;

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1) Sign up with Supabase Auth
    final authRes = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    // if (authRes.error != null || authRes.user == null) {
    //   setState(() {
    //     _errorMessage = authRes.error?.message ?? 'Signup failed';
    //     _isLoading    = false;
    //   });
    //   return;
    // }
    final userId = authRes.user!.id;

    // 2) Insert into 'users' table WITHOUT .execute()
    final insertRes = await supabase.from('users').insert({
      'user_id': userId,
      'email': email,
      'name': email,
    })
        // .select() is optional if you need the row back:
        .select(); // returns List<Map<String,dynamic>> :contentReference[oaicite:2]{index=2}

    // if (insertRes.error != null) {
    //   setState(() {
    //     _errorMessage = insertRes.error!.message;
    //     _isLoading    = false;
    //   });
    //   return;
    // }

    // 3) On success, navigate away
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.chevron_left),
        ),
        title: Text('Register'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Register',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text('Register'),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
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
