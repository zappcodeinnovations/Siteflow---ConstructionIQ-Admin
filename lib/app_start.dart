import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';
import 'core/services/auth_service.dart';
import 'modules/dashboard/dashboard_controller.dart';
import 'core/routes/app_routes.dart';
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
    // Short minimum so the branding is seen; the real wait is the profile +
    // dashboard loading below, which runs alongside it.
    final minimumSplash = Future.delayed(const Duration(milliseconds: 1200));

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
              userId: user['id'],
            );
            await AuthService.savePermissions(user['permissions']);
          }
        }
      } catch (_) {
        // Keep the cached session available when the device is temporarily offline.
      }

      // Load the dashboard while the splash is showing so it opens ready
      // instead of showing a second loading spinner. Capped so a slow
      // network never holds the splash; the dashboard then loads itself.
      if (await AuthService.can('dashboard')) {
        await DashboardController.prefetch().timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
      }
    }

    await minimumSplash;

    if (!mounted) return;

    // Fade from the splash into the app. Route names are kept because other
    // screens navigate back to '/home' by name.
    final route = isLoggedIn ? '/home' : '/login';
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: RouteSettings(name: route),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppRoutes.routes[route]!(context),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while deciding the app flow
    return const SplashScreen();
  }
}
