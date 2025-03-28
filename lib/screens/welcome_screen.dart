import 'package:flutter/material.dart';
import '../route_generator.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              child: Text('Register'),
              onPressed: () =>
                  Navigator.pushNamed(context, RouteGenerator.registerPage),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () =>
                  Navigator.pushNamed(context, RouteGenerator.loginPage),
            ),
          ],
        ),
      ),
    );
  }
}
