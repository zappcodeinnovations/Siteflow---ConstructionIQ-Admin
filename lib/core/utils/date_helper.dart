import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

class DateHelper {
  static const String defaultUkTimezone = 'Europe/London';
  static String? _cachedTimezone;

  /// Sets or overrides the active application timezone.
  static void setAppTimezone(String tz) {
    _cachedTimezone = tz;
  }

  /// Returns the configured application timezone. Defaults to "Europe/London" (UK timezone setting)
  /// matching the Euroside ConstructionIQ backend configuration.
  static Future<String> getDeviceTimezone() async {
    if (_cachedTimezone != null && _cachedTimezone!.isNotEmpty) {
      return _cachedTimezone!;
    }

    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      String tzName = '';
      try {
        tzName = (tz as dynamic).identifier?.toString().trim() ?? '';
      } catch (_) {}
      if (tzName.isEmpty) {
        tzName = tz.toString().trim();
      }
      // If the device explicitly resolved to a UK / European timezone, cache it
      if (tzName.isNotEmpty && tzName != 'null') {
        // Respect UK timezone configuration as default
        _cachedTimezone = defaultUkTimezone;
        return _cachedTimezone!;
      }
    } catch (e) {
      debugPrint("[DateHelper] Error getting timezone: $e");
    }

    _cachedTimezone = defaultUkTimezone;
    return _cachedTimezone!;
  }

  /// Converts a UTC DateTime to Europe/London (GMT / BST) DateTime.
  static DateTime toUkDateTime(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    final year = utc.year;

    // Last Sunday of March at 01:00 UTC (BST starts)
    final march31 = DateTime.utc(year, 3, 31);
    final lastSundayMarch = 31 - (march31.weekday % 7);
    final bstStart = DateTime.utc(year, 3, lastSundayMarch, 1, 0, 0);

    // Last Sunday of October at 01:00 UTC (BST ends)
    final oct31 = DateTime.utc(year, 10, 31);
    final lastSundayOct = 31 - (oct31.weekday % 7);
    final bstEnd = DateTime.utc(year, 10, lastSundayOct, 1, 0, 0);

    final isBst = (utc.isAfter(bstStart) || utc.isAtSameMomentAs(bstStart)) && utc.isBefore(bstEnd);
    final offsetHours = isBst ? 1 : 0;
    return utc.add(Duration(hours: offsetHours));
  }

  /// Formats a date string to the configured UK operational timezone (Europe/London: GMT/BST).
  static String formatToUkTime(String? rawDate, {bool includeTime = true}) {
    if (rawDate == null || rawDate.trim().isEmpty || rawDate == 'null' || rawDate == '-') {
      return '-';
    }

    final trimmed = rawDate.trim();

    // 1. If it has explicit UTC or timezone offset
    final hasExplicitOffset = trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);

    if (hasExplicitOffset) {
      try {
        final parsed = DateTime.tryParse(trimmed);
        if (parsed != null) {
          final uk = toUkDateTime(parsed);
          final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
          return format.format(uk);
        }
      } catch (_) {}
    }

    // 2. Try parsing custom formatted strings as UTC
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
        final uk = toUkDateTime(DateTime.utc(
          date.year,
          date.month,
          date.day,
          date.hour,
          date.minute,
          date.second,
        ));
        final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
        return format.format(uk);
      } catch (_) {}
    }

    // 3. Try parsing ISO string
    try {
      final isoStr = trimmed.replaceAll(' ', 'T');
      final parsed = DateTime.tryParse(isoStr) ?? DateTime.tryParse(trimmed);
      if (parsed != null) {
        final uk = toUkDateTime(parsed);
        final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
        return format.format(uk);
      }
    } catch (_) {}

    return trimmed;
  }

  /// Formats a date string to the configured operational timezone (dd/MM/yyyy hh:mm a).
  static String formatToLocal(String? rawDate, {bool includeTime = true}) {
    return formatToUkTime(rawDate, includeTime: includeTime);
  }

  /// Formats a date string (e.g. "yyyy-MM-dd" or ISO format) to "dd/MM/yyyy".
  static String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty || rawDate == '-' || rawDate == 'null') {
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
