import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.i("Handling a background message: ${message.messageId}", tag: "FCM");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Always start in the white theme. Users can still switch to dark mode from
// Settings, but the device's system theme no longer forces a dark first load.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log Flutter framework errors with full details in terminal
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.e(
      "Flutter Framework Error: ${details.exceptionAsString()}",
      error: details.exception,
      stackTrace: details.stack,
      tag: "FLUTTER_ERROR",
    );
  };

  // Catch unhandled asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e(
      "Unhandled Async Error: $error",
      error: error,
      stackTrace: stack,
      tag: "ASYNC_ERROR",
    );
    return true;
  };

  AppLogger.i("🚀 Initializing SiteFlow Admin Application...", tag: "INIT");

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.i("FCM Authorization Status: ${settings.authorizationStatus}", tag: "FCM");
  } catch (e, stack) {
    AppLogger.e("Failed to initialize Firebase", error: e, stackTrace: stack, tag: "FCM");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [
            AppNavigatorObserver(),
          ],
          debugShowCheckedModeBanner: false,
          title: 'SiteFlow - Admin',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/',
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
