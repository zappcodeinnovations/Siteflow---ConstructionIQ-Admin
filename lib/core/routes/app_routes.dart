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
import 'package:euroside_admin/modules/home/nav_bar.dart';
import 'package:euroside_admin/modules/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const AppStart(),
    '/login': (context) => const LoginScreen(),
    '/forgot_password': (context) => const ForgotPasswordScreen(),
    '/register': (context) => const RegistrationScreen(),
    '/home': (context) => const BottomNavScreen(),
    '/profile': (context) => const ProfileScreen(),
    '/jobSheet': (context) => const JobSheetScreen(),
    '/productivity': (context) => const ProductivityScreen(),
    '/timesheet': (context) => const TimesheetScreen(),
    '/managerAttendance': (context) => const ManagerAttendanceScreen(),
    '/library': (context) => const LibraryScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/admin': (context) => const AdminScreen(),
  };
}