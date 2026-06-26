import 'dart:async';
import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'modules/splash/splash_screen.dart';

class AppStart extends StatefulWidget {
  const AppStart({super.key});

  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Determine auth status
    final isLoggedIn = await AuthService.isLoggedIn();
    
    // Delay to simulate splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while deciding the app flow
    return const SplashScreen();
  }
}
