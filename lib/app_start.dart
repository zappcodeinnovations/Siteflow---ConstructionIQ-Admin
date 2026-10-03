import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';
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
    if (isLoggedIn) {
      try {
        final response = await ApiClient.get(
          ApiEndpoints.baseUrl + ApiEndpoints.profile,
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final user = (data['data'] ?? data)['user'];
          if (user is Map) {
            await AuthService.saveUserRole(
              effectiveRole: user['effective_role']?.toString() ?? '',
              roleLabel: user['role_label']?.toString(),
            );
            await AuthService.savePermissions(user['permissions']);
          }
        }
      } catch (_) {
        // Keep the cached session available when the device is temporarily offline.
      }
    }

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
