import 'package:euroside_admin/app_start.dart';
import 'package:euroside_admin/modules/auth/login_screen.dart';
import 'package:euroside_admin/modules/auth/forgot_password_screen.dart';
import 'package:euroside_admin/modules/auth/registration_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/admin_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/job_sheet_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/library_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/productivity_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/settings_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/timesheet_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/manager_attendance_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/weekly_diary_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/manager_diary_list_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/my_approvals_screen.dart';
import 'package:euroside_admin/modules/drawer_pages/workforce_planner_screen.dart';
import 'package:euroside_admin/modules/home/nav_bar.dart';
import 'package:euroside_admin/modules/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PermissionGate extends StatelessWidget {
  final String menuKey;
  final Widget child;

  const PermissionGate({super.key, required this.menuKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.can(menuKey),
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
        return child;
      },
    );
  }
}

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const AppStart(),
    '/login': (context) => const LoginScreen(),
    '/forgot_password': (context) => const ForgotPasswordScreen(),
    '/register': (context) => const RegistrationScreen(),
    '/home': (context) => const BottomNavScreen(),
    '/profile': (context) => const ProfileScreen(),
    '/jobSheet': (context) =>
        const PermissionGate(menuKey: 'job_sheets', child: JobSheetScreen()),
    '/dailyReports': (context) => const PermissionGate(
      menuKey: 'daily_reports',
      child: JobSheetScreen(title: "Daily Reports", dailyReportsMode: true),
    ),
    '/weeklyDiary': (context) => const PermissionGate(
      menuKey: 'weekly_diary',
      child: WeeklyDiaryScreen(),
    ),
    '/managerDiary': (context) => const PermissionGate(
      menuKey: 'manager_diary',
      child: ManagerDiaryListScreen(),
    ),
    '/myApprovals': (context) =>
        const PermissionGate(menuKey: 'approvals', child: MyApprovalsScreen()),
    '/productivity': (context) => const PermissionGate(
      menuKey: 'productivity',
      child: ProductivityScreen(),
    ),
    '/workforcePlanner': (context) => const PermissionGate(
      menuKey: 'workforce_planner',
      child: WorkforcePlannerScreen(),
    ),
    '/timesheet': (context) =>
        const PermissionGate(menuKey: 'timesheets', child: TimesheetScreen()),
    '/managerAttendance': (context) => const PermissionGate(
      menuKey: 'manager_attendance',
      child: ManagerAttendanceScreen(),
    ),
    '/library': (context) =>
        const PermissionGate(menuKey: 'library', child: LibraryScreen()),
    '/settings': (context) =>
        const PermissionGate(menuKey: 'settings', child: SettingsScreen()),
    '/admin': (context) => const AdminScreen(),
  };
}
