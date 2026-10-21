import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/admin_notification_model.dart';
import 'auth_service.dart';

/// Tracks which notifications the logged-in user has already seen, so the
/// bell badge counts only new ones. Notification ids only ever increase, so
/// "seen" is stored as the highest id the user has viewed (per user, so a
/// different login on the same device starts with its own state).
class NotificationSeenService {
  NotificationSeenService._();

  /// Highest notification id the current user has seen. Every app bar
  /// listens to this, so opening the list clears the badge everywhere.
  static final ValueNotifier<int> lastSeenId = ValueNotifier<int>(0);

  static Future<String> _key() async {
    final userId = await AuthService.getUserId();
    return 'notifications_last_seen_id_${userId ?? 'unknown'}';
  }

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      lastSeenId.value = prefs.getInt(await _key()) ?? 0;
    } catch (_) {
      // Keep the in-memory value; the badge just may show stale counts.
    }
  }

  /// Number of active notifications newer than the last one seen.
  static int unreadCount(Iterable<AdminNotification> notifications) =>
      notifications.where((n) => n.isActive && n.id > lastSeenId.value).length;

  /// Marks everything in [notifications] as seen. Pass the unfiltered list
  /// only, otherwise hidden (filtered-out) notifications would be marked too.
  static Future<void> markSeen(
    Iterable<AdminNotification> notifications,
  ) async {
    var maxId = lastSeenId.value;
    for (final n in notifications) {
      if (n.id > maxId) maxId = n.id;
    }
    if (maxId == lastSeenId.value) return;
    lastSeenId.value = maxId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(await _key(), maxId);
    } catch (_) {}
  }
}
