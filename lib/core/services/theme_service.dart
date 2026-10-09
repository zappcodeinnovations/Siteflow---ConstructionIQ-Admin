import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class ThemeService {
  static const String _themePrefKey = 'app_theme_mode';

  /// Fetches saved theme preference from local storage.
  /// Defaults to [ThemeMode.light] if no preference was previously saved.
  static Future<ThemeMode> getSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedValue = prefs.getString(_themePrefKey);
      if (savedValue == 'dark') return ThemeMode.dark;
      if (savedValue == 'light') return ThemeMode.light;
      if (savedValue == 'system') return ThemeMode.system;
    } catch (e) {
      AppLogger.w("Error loading theme preference: $e", tag: "THEME");
    }
    return ThemeMode.light;
  }

  /// Persists theme preference to local storage.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String value = 'light';
      if (mode == ThemeMode.dark) {
        value = 'dark';
      } else if (mode == ThemeMode.system) {
        value = 'system';
      }
      await prefs.setString(_themePrefKey, value);
      AppLogger.i("Saved theme preference: $value", tag: "THEME");
    } catch (e) {
      AppLogger.e("Error saving theme preference", error: e, tag: "THEME");
    }
  }
}
