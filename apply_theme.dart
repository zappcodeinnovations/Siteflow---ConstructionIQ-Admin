// Dart CLI utility to apply corporateBlue dark/light theme to admin views.
// Run from the project root with: dart apply_theme.dart

import 'dart:io';

const String appThemeImport =
    "import '../../../../core/theme/app_theme.dart';";

const String themeVars = """
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final headerBg = isDark ? AppTheme.corporateBlue : Colors.grey.shade50;
    final headerTitle = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final searchFillColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;
""";

const List<String> filesToCheck = [
  'lib/modules/drawer_pages/admin/admin_members_view.dart',
  'lib/modules/drawer_pages/admin/admin_guests_view.dart',
  'lib/modules/drawer_pages/admin/admin_announcements_view.dart',
  'lib/modules/drawer_pages/admin/admin_notifications_view.dart',
  'lib/modules/drawer_pages/admin/admin_permissions_view.dart',
  'lib/modules/drawer_pages/admin/admin_activity_logs_view.dart',
  'lib/modules/drawer_pages/admin/admin_organisation_view.dart',
  'lib/modules/drawer_pages/admin/admin_support_view.dart',
];

void main() {
  print('=== Admin Theme Checker ===\n');

  for (final path in filesToCheck) {
    final file = File(path);
    if (!file.existsSync()) {
      print('[$path] ❌ File not found');
      continue;
    }

    final content = file.readAsStringSync();

    final hasImport = content.contains("app_theme.dart");
    final hasIsDark = content.contains("isDark");
    final hasCorporateBlue = content.contains("AppTheme.corporateBlue");
    final hasHardcodedWhite =
        RegExp(r'color:\s*Colors\.white\b').hasMatch(content);

    final status = (hasImport && hasIsDark && hasCorporateBlue) ? '✅' : '⚠️ ';
    print('$status $path');
    print('   • app_theme import : ${hasImport ? "✅" : "❌ MISSING"}');
    print('   • isDark check     : ${hasIsDark ? "✅" : "❌ MISSING"}');
    print('   • corporateBlue    : ${hasCorporateBlue ? "✅" : "❌ MISSING"}');
    if (hasHardcodedWhite) {
      print('   • ⚠️  Hardcoded Colors.white found — may need updating');
    }
    print('');
  }

  print('Done. All files checked.');
}
