import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_drawer.dart';
import 'admin/admin_activity_logs_view.dart';

/// Manager/supervisor replacement for Admin Control: only the activity logs
/// of the operatives in the teams they lead (scoped by the backend).
class OperativeLogsScreen extends StatelessWidget {
  const OperativeLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<bool>(
      future: AuthService.canViewOperativeLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access denied')),
            body: const Center(
              child: Text('You do not have permission to view this section.'),
            ),
          );
        }
        return Scaffold(
          backgroundColor: isDark
              ? AppTheme.darkBackground
              : const Color(0xFFF8FAFC),
          drawer: const CustomDrawer(),
          appBar: AppBar(
            leading: const AppNavLeading(),
            leadingWidth: AppNavigation.backAndMenuLeadingWidth,
            title: const Text(
              'OPERATIVE LOGS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF101A26)
                : const Color(0xFF0F2C4A),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundStripesPainter(isDark: isDark),
                ),
              ),
              const SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AdminActivityLogsView(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
