import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Keeps the last successful response of a list screen's first page so the
/// screen can show it instantly next time, while fresh data loads.
///
/// Stored per logged-in user, so a different login on the same device never
/// sees someone else's cached list.
class ResponseCache {
  ResponseCache._();

  static Future<String> _key(String name) async {
    final userId = await AuthService.getUserId();
    return 'response_cache_${name}_${userId ?? 'unknown'}';
  }

  static Future<String?> read(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(await _key(name));
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String name, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _key(name), body);
    } catch (_) {
      // Caching is best-effort; the screen still works without it.
    }
  }
}
