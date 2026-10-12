import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

class DateHelper {
  /// UTC is only a safe fallback when the native platform cannot report its
  /// IANA timezone.  Do not default all mobile users to the UK: that made an
  /// India-based admin see a different timestamp than the web portal.
  static const String defaultTimezone = 'UTC';

  /// Retained for the few places that explicitly request a UK conversion.
  static const String defaultUkTimezone = 'Europe/London';
  static String? _cachedTimezone;

  static const Map<String, String> _timezoneAliases = {
    'Asia/Calcutta': 'Asia/Kolkata',
  };

  static String _canonicalTimezone(String timezone) =>
      _timezoneAliases[timezone.trim()] ?? timezone.trim();

  /// Sets or overrides the active application timezone.
  static void setAppTimezone(String tz) {
    _cachedTimezone = _canonicalTimezone(tz);
  }

  /// Returns the device's real IANA timezone for API display payloads.
  static Future<String> getDeviceTimezone() async {
    if (_cachedTimezone != null && _cachedTimezone!.isNotEmpty) {
      return _cachedTimezone!;
    }

    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      final tzName = _canonicalTimezone(tz.identifier);
      if (tzName.isNotEmpty && tzName != 'null') {
        _cachedTimezone = tzName;
        return _cachedTimezone!;
      }
    } catch (e) {
      debugPrint("[DateHelper] Error getting timezone: $e");
    }

    _cachedTimezone = defaultTimezone;
    return _cachedTimezone!;
  }

  static bool _isBst(DateTime utc) {
    final year = utc.year;

    // Last Sunday of March at 01:00 UTC (BST starts)
    final march31 = DateTime.utc(year, 3, 31);
    final lastSundayMarch = 31 - (march31.weekday % 7);
    final bstStart = DateTime.utc(year, 3, lastSundayMarch, 1, 0, 0);

    // Last Sunday of October at 01:00 UTC (BST ends)
    final oct31 = DateTime.utc(year, 10, 31);
    final lastSundayOct = 31 - (oct31.weekday % 7);
    final bstEnd = DateTime.utc(year, 10, lastSundayOct, 1, 0, 0);

    return (utc.isAfter(bstStart) || utc.isAtSameMomentAs(bstStart)) &&
        utc.isBefore(bstEnd);
  }

  /// Converts a UTC DateTime to Europe/London (GMT / BST) DateTime.
  static DateTime toUkDateTime(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    final offsetHours = _isBst(utc) ? 1 : 0;
    return utc.add(Duration(hours: offsetHours));
  }

  /// Returns "BST" or "GMT" for the given moment, so a displayed UK time
  /// can carry an explicit label instead of leaving the reader to guess
  /// whether it's already timezone-adjusted.
  static String ukTimezoneAbbreviation(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return _isBst(utc) ? 'BST' : 'GMT';
  }

  static DateTime? _parseServerTimestamp(String rawDate) {
    final trimmed = rawDate.trim();
    final hasExplicitOffset =
        trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);

    if (hasExplicitOffset) {
      return DateTime.tryParse(trimmed);
    }

    // Historical endpoints sent unqualified server timestamps.  Those were
    // UTC, so make that explicit before converting to the device timezone.
    final patterns = [
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-ddTHH:mm:ss',
      'dd MMM yyyy hh:mm:ss a',
      'dd MMM yyyy hh:mm a',
      'dd MMM yyyy HH:mm:ss',
      'dd MMM yyyy HH:mm',
      'dd MMMM yyyy hh:mm a',
      'dd MMMM yyyy HH:mm',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy hh:mm a',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
    ];

    for (final pattern in patterns) {
      try {
        final date = DateFormat(pattern, 'en_US').parse(trimmed);
        return DateTime.utc(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
        );
      } catch (_) {}
    }

    final parsed =
        DateTime.tryParse(trimmed.replaceAll(' ', 'T')) ??
        DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    return parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
          );
  }

  /// Formats a date string to the explicitly requested UK operational
  /// timezone. Use [formatToLocal] for normal mobile UI timestamps.
  static String formatToUkTime(String? rawDate, {bool includeTime = true}) {
    if (rawDate == null ||
        rawDate.trim().isEmpty ||
        rawDate == 'null' ||
        rawDate == '-') {
      return '-';
    }

    final parsed = _parseServerTimestamp(rawDate);
    if (parsed == null) return rawDate.trim();
    final format = includeTime
        ? DateFormat('dd/MM/yyyy hh:mm a')
        : DateFormat('dd/MM/yyyy');
    return format.format(toUkDateTime(parsed));
  }

  /// Formats a server timestamp in the viewer's real device timezone.
  /// API responses include an offset for the requested X-Timezone, and Dart
  /// converts that instant safely to the same device timezone for display.
  static String formatToLocal(String? rawDate, {bool includeTime = true}) {
    if (rawDate == null ||
        rawDate.trim().isEmpty ||
        rawDate == 'null' ||
        rawDate == '-') {
      return '-';
    }

    final parsed = _parseServerTimestamp(rawDate);
    if (parsed == null) return rawDate.trim();
    final format = includeTime
        ? DateFormat('dd/MM/yyyy hh:mm a')
        : DateFormat('dd/MM/yyyy');
    return format.format(parsed.toLocal());
  }

  /// Formats a date string (e.g. "yyyy-MM-dd" or ISO format) to "dd/MM/yyyy".
  static String formatDate(String? rawDate) {
    if (rawDate == null ||
        rawDate.trim().isEmpty ||
        rawDate == '-' ||
        rawDate == 'null') {
      return '-';
    }

    final trimmed = rawDate.trim();

    // 1. If already in dd/MM/yyyy format
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed)) {
      return trimmed;
    }

    // 2. Direct check for yyyy-MM-dd format to avoid UTC/local timezone day shifts
    final ymdMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (ymdMatch != null) {
      return '${ymdMatch.group(3)}/${ymdMatch.group(2)}/${ymdMatch.group(1)}';
    }

    // 3. Fallback to parsing
    try {
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return DateFormat('dd/MM/yyyy').format(parsed);
      }
    } catch (_) {}

    return trimmed;
  }
}
