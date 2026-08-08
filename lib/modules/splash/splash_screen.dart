import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}