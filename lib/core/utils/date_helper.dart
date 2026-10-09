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

  /// Formats a date string to the user's local timezone (dd/MM/yyyy hh:mm a).
  static String formatToLocal(String? rawDate, {bool includeTime = true}) {
    if (rawDate == null || rawDate.trim().isEmpty || rawDate == 'null' || rawDate == '-') {
      return '-';
    }

    final trimmed = rawDate.trim();

    // 1. If it's already in dd/MM/yyyy hh:mm a format (e.g. "03/10/2026 11:30 AM")
    final formattedPattern = RegExp(r'^\d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}\s*(AM|PM|am|pm)', caseSensitive: false);
    if (formattedPattern.hasMatch(trimmed)) {
      return trimmed;
    }

    // 2. If it contains explicit UTC / timezone offset (e.g. "2026-10-05T13:24:00Z" or "...+05:30")
    final hasExplicitOffset = trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);

    if (hasExplicitOffset) {
      try {
        final parsed = DateTime.tryParse(trimmed);
        if (parsed != null) {
          final local = parsed.toLocal();
          final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
          return format.format(local);
        }
      } catch (_) {}
    }

    // 3. Try parsing custom formatted strings (e.g. "05 Oct 2026 06:54 pm" or "05 Oct 2026 18:54:00")
    final patterns = [
      'dd MMM yyyy hh:mm:ss a',
      'dd MMM yyyy hh:mm a',
      'dd MMM yyyy HH:mm:ss',
      'dd MMM yyyy HH:mm',
      'dd MMMM yyyy hh:mm a',
      'dd MMMM yyyy HH:mm',
      'dd MMM yyyy',
      'dd MMMM yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-ddTHH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
    ];

    for (final pattern in patterns) {
      try {
        final date = DateFormat(pattern, 'en_US').parse(trimmed);
        final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
        return format.format(date);
      } catch (_) {}
    }

    // 4. Try parsing standard ISO string without explicit offset
    try {
      final isoStr = trimmed.replaceAll(' ', 'T');
      final parsed = DateTime.tryParse(isoStr) ?? DateTime.tryParse(trimmed);
      if (parsed != null) {
        final format = includeTime ? DateFormat('dd/MM/yyyy hh:mm a') : DateFormat('dd/MM/yyyy');
        return format.format(parsed);
      }
    } catch (_) {}

    return trimmed;
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
