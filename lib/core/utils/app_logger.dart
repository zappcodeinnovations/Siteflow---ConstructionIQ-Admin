import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized Logger for SiteFlow Admin app.
/// Provides rich, colorized console output during `flutter run` for:
/// - Outgoing HTTP requests and incoming HTTP responses (with payload formatting & latency)
/// - Navigation and route transitions
/// - State / controller actions and lifecycle events
/// - Detailed warnings, errors, and unhandled exceptions
class AppLogger {
  // ANSI Escape Codes for Colorized Console Outputs in terminal / flutter run
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';
  static const String _bold = '\x1B[1m';

  static final JsonEncoder _prettyEncoder = const JsonEncoder.withIndent('  ');

  /// Internal log dispatcher using dart:developer to avoid truncation on large payloads
  static void _log(String message, {String tag = 'APP', String color = ''}) {
    if (!kDebugMode) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = '$color[$tag $timestamp]$_reset';
    developer.log('$prefix $message', name: tag);
    // Also use debugPrint for direct terminal stdout visibility on all platforms
    debugPrint('$prefix $message');
  }

  /// Format an arbitrary payload (Map, List, or JSON String) into a pretty indented string
  static String formatJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is String) {
        if (data.trim().startsWith('{') || data.trim().startsWith('[')) {
          final decoded = jsonDecode(data);
          return _prettyEncoder.convert(decoded);
        }
        return data;
      }
      if (data is Map || data is List) {
        return _prettyEncoder.convert(data);
      }
    } catch (_) {
      // Return raw string if JSON parsing fails
    }
    return data.toString();
  }

  /// Log Debug information
  static void d(String message, {String tag = 'DEBUG'}) {
    _log('🐞 $message', tag: tag, color: _gray);
  }

  /// Log Informational messages
  static void i(String message, {String tag = 'INFO'}) {
    _log('💡 $message', tag: tag, color: _cyan);
  }

  /// Log Warnings
  static void w(String message, {String tag = 'WARN'}) {
    _log('⚠️ $message', tag: tag, color: _yellow);
  }

  /// Log Errors and Exceptions
  static void e(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String tag = 'ERROR',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('❌ $message');
    if (error != null) {
      buffer.writeln('   Details: $error');
    }
    if (stackTrace != null) {
      buffer.writeln('   Stack: $stackTrace');
    }
    _log(buffer.toString(), tag: tag, color: _red);
  }

  /// Log Navigation / Route changes
  static void nav(String message) {
    _log('🧭 [ROUTE] $message', tag: 'NAV', color: _magenta);
  }

  /// Log HTTP Request Details
  static void request(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln('┌── 🌐 [HTTP REQUEST] $_bold$method$_reset $url');
    if (headers != null && headers.isNotEmpty) {
      // Redact sensitive headers for safety
      final safeHeaders = Map<String, String>.from(headers);
      if (safeHeaders.containsKey('Authorization')) {
        final auth = safeHeaders['Authorization']!;
        if (auth.length > 20) {
          safeHeaders['Authorization'] = '${auth.substring(0, 15)}... (hidden)';
        }
      }
      buffer.writeln('│ 📋 Headers: $safeHeaders');
    }
    if (body != null) {
      final formattedBody = formatJson(body);
      final lines = formattedBody.split('\n');
      buffer.writeln('│ 📦 Body:');
      for (final line in lines) {
        buffer.writeln('│   $line');
      }
    }
    buffer.write('└──────────────────────────────────────────────────────────');
    _log(buffer.toString(), tag: 'HTTP', color: _blue);
  }

  /// Log HTTP Response Details
  static void response(
    String method,
    String url,
    int statusCode, {
    dynamic body,
    int? durationMs,
  }) {
    if (!kDebugMode) return;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final isWarning = statusCode >= 400 && statusCode < 500;

    final color = isSuccess
        ? _green
        : isWarning
            ? _yellow
            : _red;
    final statusIcon = isSuccess
        ? '✅'
        : isWarning
            ? '⚠️'
            : '❌';

    final buffer = StringBuffer();
    final durationText = durationMs != null ? ' (${durationMs}ms)' : '';
    buffer.writeln(
      '┌── $statusIcon [HTTP $statusCode] $_bold$method$_reset $url$durationText',
    );

    if (body != null && body.toString().isNotEmpty) {
      final formattedBody = formatJson(body);
      final lines = formattedBody.split('\n');
      buffer.writeln('│ 📥 Response Body:');
      // Limit to 60 lines in output to keep console readable
      const maxLines = 60;
      final displayLines = lines.take(maxLines).toList();
      for (final line in displayLines) {
        buffer.writeln('│   $line');
      }
      if (lines.length > maxLines) {
        buffer.writeln('│   ... [${lines.length - maxLines} lines truncated]');
      }
    } else {
      buffer.writeln('│ 📥 Response: <Empty body>');
    }
    buffer.write('└──────────────────────────────────────────────────────────');
    _log(buffer.toString(), tag: 'HTTP', color: color);
  }

  /// Log Network Exception / Timeout
  static void networkError(
    String method,
    String url,
    dynamic error, {
    StackTrace? stackTrace,
    int? durationMs,
  }) {
    if (!kDebugMode) return;
    final durationText = durationMs != null ? ' (${durationMs}ms)' : '';
    final buffer = StringBuffer();
    buffer.writeln('┌── 💥 [HTTP NETWORK ERROR] $_bold$method$_reset $url$durationText');
    buffer.writeln('│ Error: $error');
    if (stackTrace != null) {
      buffer.writeln('│ Stack: $stackTrace');
    }
    buffer.write('└──────────────────────────────────────────────────────────');
    _log(buffer.toString(), tag: 'HTTP', color: _red);
  }
}

/// NavigatorObserver that logs route pushes, pops, and replaces
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? route.runtimeType.toString();
    final prevName = previousRoute?.settings.name ?? previousRoute?.runtimeType.toString();
    AppLogger.nav('Pushed: $routeName (from: $prevName)');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = route.settings.name ?? route.runtimeType.toString();
    final prevName = previousRoute?.settings.name ?? previousRoute?.runtimeType.toString();
    AppLogger.nav('Popped: $routeName (back to: $prevName)');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = newRoute?.settings.name ?? newRoute?.runtimeType.toString();
    final oldName = oldRoute?.settings.name ?? oldRoute?.runtimeType.toString();
    AppLogger.nav('Replaced: $oldName -> $newName');
  }
}
