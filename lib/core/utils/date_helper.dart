import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

class DateHelper {
  static String? _cachedTimezone;

  /// Returns the device IANA timezone identifier (e.g. "Asia/Calcutta", "Europe/London").
  static Future<String> getDeviceTimezone() async {
    if (_cachedTimezone != null && _cachedTimezone!.isNotEmpty) {
      return _cachedTimezone!;
    }
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      final tzName = tz.toString().trim();
      if (tzName.isNotEmpty && tzName != 'null') {
        _cachedTimezone = tzName;
        return _cachedTimezone!;
      }
    } catch (e) {
      debugPrint("[DateHelper] Error getting timezone from FlutterTimezone: $e");
    }

    // Fallback based on device offset and name
    final offset = DateTime.now().timeZoneOffset;
    final totalMinutes = offset.inMinutes;

    if (totalMinutes == 330) {
      _cachedTimezone = 'Asia/Calcutta';
    } else if (totalMinutes == 0 || totalMinutes == 60) {
      _cachedTimezone = 'Europe/London';
    } else if (totalMinutes == -300 || totalMinutes == -240) {
      _cachedTimezone = 'America/New_York';
    } else if (totalMinutes == -480 || totalMinutes == -420) {
      _cachedTimezone = 'America/Los_Angeles';
    } else if (totalMinutes == 480) {
      _cachedTimezone = 'Asia/Singapore';
    } else if (totalMinutes == 600) {
      _cachedTimezone = 'Australia/Sydney';
    } else if (totalMinutes == 240) {
      _cachedTimezone = 'Asia/Dubai';
    } else {
      _cachedTimezone = 'Asia/Calcutta';
    }

    return _cachedTimezone!;
  }

  /// Formats a date string to the user's local timezone (dd/MM/yyyy hh:mm a).
  static String formatToLocal(String? rawDate, {bool includeTime = true}) {
    if (rawDate == null || rawDate.trim().isEmpty || rawDate == 'null' || rawDate == '-') {
      return '-';
    }

    final trimmed = rawDate.trim();

    // 1. If it's already in dd/MM/yyyy hh:mm a format (e.g. "03/10/2026 11:30 AM")
    final formattedPattern = RegExp(r'^\d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}\s*(AM|PM|am|pm)?');
    if (formattedPattern.hasMatch(trimmed) &&
        (trimmed.contains('AM') || trimmed.contains('PM') || trimmed.contains('am') || trimmed.contains('pm'))) {
      return trimmed;
    }

    // 2. Try parsing standard ISO 8601 formats
    try {
      DateTime? parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        final local = parsed.toLocal();
        final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
        return format.format(local);
      }
    } catch (_) {}

    // 3. Try parsing custom formats
    for (final pattern in [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'dd-MM-yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
    ]) {
      try {
        final date = DateFormat(pattern).parseUtc(trimmed);
        final local = date.toLocal();
        final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
        return format.format(local);
      } catch (_) {}
    }

    return trimmed;
  }
}
