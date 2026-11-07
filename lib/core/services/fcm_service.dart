import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Main entry point to initialize notifications based on platform
  static Future<void> initialize() async {
    try {
      if (Platform.isIOS) {
        await _initIos();
      } else if (Platform.isAndroid) {
        await _initAndroid();
      }
    } catch (e, stack) {
      AppLogger.e("FCM Init failed", error: e, stackTrace: stack, tag: "FCM");
    }
  }

  /// Unified getter that delegates to platform-specific token fetchers
  static Future<String?> getDeviceToken() async {
    try {
      if (Platform.isIOS) {
        return await _getIosToken();
      } else if (Platform.isAndroid) {
        return await _getAndroidToken();
      }
      return await _messaging.getToken();
    } catch (e, stack) {
      AppLogger.e("Error getting device token", error: e, stackTrace: stack, tag: "FCM");
      return null;
    }
  }

  // -------------------------------------------------------------
  // ANDROID SPECIFIC IMPLEMENTATION
  // -------------------------------------------------------------
  static Future<void> _initAndroid() async {
    AppLogger.i("Initializing Android FCM...", tag: "FCM");
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.i(
      "Android Notification status: ${settings.authorizationStatus}",
      tag: "FCM",
    );
  }

  static Future<String?> _getAndroidToken() async {
    AppLogger.i("Fetching Android FCM Token...", tag: "FCM");
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        AppLogger.i("Android FCM Token retrieved successfully", tag: "FCM");
      } else {
        AppLogger.w("Android FCM Token is null or empty", tag: "FCM");
      }
      return token;
    } catch (e, stack) {
      AppLogger.e("Failed to get Android FCM Token", error: e, stackTrace: stack, tag: "FCM");
      return null;
    }
  }

  // -------------------------------------------------------------
  // iOS SPECIFIC IMPLEMENTATION
  // -------------------------------------------------------------
  static Future<void> _initIos() async {
    AppLogger.i("Initializing iOS FCM...", tag: "FCM");

    // 1. Request iOS Notification Permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    AppLogger.i(
      "iOS Notification status: ${settings.authorizationStatus}",
      tag: "FCM",
    );

    // 2. Set foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<String?> _getIosToken() async {
    AppLogger.i("Fetching iOS FCM Token...", tag: "FCM");

    // On real iOS devices, APNs token MUST be available before FCM getToken works.
    // Retry briefly (up to 3 times) to allow APNs registration to complete.
    String? apnsToken;
    for (int i = 0; i < 3; i++) {
      apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        AppLogger.i("iOS APNs Token available on attempt ${i + 1}", tag: "FCM");
        break;
      }
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (apnsToken == null && !kDebugMode) {
      AppLogger.w("APNs token not yet available on iOS device", tag: "FCM");
    }

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        AppLogger.i("iOS FCM Token retrieved successfully", tag: "FCM");
      } else {
        AppLogger.w("iOS FCM Token is null or empty", tag: "FCM");
      }
      return token;
    } catch (e, stack) {
      AppLogger.e(
        "Failed to get iOS FCM token (simulator or APNs registration missing)",
        error: e,
        stackTrace: stack,
        tag: "FCM",
      );
      return null;
    }
  }

  /// Listen for token rotation/refresh
  static void setupTokenRefreshListener(Function(String newToken) onRefresh) {
    _messaging.onTokenRefresh.listen((token) {
      AppLogger.i("FCM Token Refreshed: $token", tag: "FCM");
      onRefresh(token);
    });
  }
}

