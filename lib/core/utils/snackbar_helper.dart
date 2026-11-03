import 'package:flutter/material.dart';

/// Shows an API failure as a SnackBar, styling a permission restriction
/// (HTTP 403 - "You don't have access to this feature...") as an
/// informational blue notice rather than a red/standard error, since it's
/// an expected access-level notice, not a system failure.
void showApiFailureSnackbar(
  BuildContext context, {
  required int statusCode,
  required String message,
}) {
  final isPermissionRestricted = statusCode == 403;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isPermissionRestricted ? const Color(0xFF0D6EFD) : Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
