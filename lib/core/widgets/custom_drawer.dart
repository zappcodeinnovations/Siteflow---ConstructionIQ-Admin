import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../../main.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  Set<String> _allowedMenus = {};

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    const keys = [
      'dashboard',
      'job_sheets',
      'daily_reports',
      'weekly_diary',
      'manager_diary',
      'approvals',
      'productivity',
      'workforce_planner',
      'timesheets',
      'manager_attendance',
      'library',
      'settings',
      'settings_teams',
      'settings_materials',
      'admin_members',
      'admin_guests',
      'admin_announcements',
      'admin_notifications',
      'admin_permissions',
      'admin_activity_logs',
      'admin_organisation',
      'admin_support',
    ];
    final values = await Future.wait(keys.map(AuthService.can));
    final allowed = <String>{};
    for (var i = 0; i < keys.length; i++) {
      if (values[i]) allowed.add(keys[i]);
    }
    if (mounted) {
      setState(() => _allowedMenus = allowed);
    }
  }

  Future<void> _logout() async {
    await AuthService.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    String? currentRoute,
  ) {
    // Determine if the current route matches the item's route
    final isActive = currentRoute == route;

    // Style colors
    final iconColor = isActive ? Colors.white : Colors.white70;
    final textColor = isActive ? Colors.white : Colors.white70;
    final bgColor = isActive
        ? AppTheme.corporateLightBlue.withValues(alpha: 0.3)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: bgColor,
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isActive) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              ModalRoute.withName('/home'),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: AppTheme.corporateBlue,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    "assets/images/app_icon.png",
                    height: 40,
                    width: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Euroside Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_allowedMenus.contains('dashboard'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.home,
                    "Dashboard",
                    '/home',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('job_sheets'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.document,
                    "Job Sheet",
                    '/jobSheet',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('daily_reports'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.paper,
                    "Daily Reports",
                    '/dailyReports',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('weekly_diary'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.calendar,
                    "Weekly Diary",
                    '/weeklyDiary',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('manager_diary'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.edit,
                    "Manager Diary",
                    '/managerDiary',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('approvals'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.tick_square,
                    "My Approvals",
                    '/myApprovals',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('productivity'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.graph,
                    "Productivity",
                    '/productivity',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('workforce_planner'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.calendar,
                    "Workforce Planner",
                    '/workforcePlanner',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('timesheets'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.time_circle,
                    "Timesheet",
                    '/timesheet',
                    currentRoute,
                  ),
                if (_allowedMenus.contains('manager_attendance'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.user_1,
                    "Authority Attendance",
                    '/managerAttendance',
                    currentRoute,
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(height: 1),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 8),
                  child: Text(
                    "SYSTEM & CONFIG",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                if (_allowedMenus.contains('library'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.bookmark,
                    "Library",
                    '/library',
                    currentRoute,
                  ),

                if (_allowedMenus.contains('settings') ||
                    _allowedMenus.contains('settings_teams') ||
                    _allowedMenus.contains('settings_materials'))
                  _buildDrawerItem(
                    context,
                    IconlyLight.setting,
                    "Settings",
                    '/settings',
                    currentRoute,
                  ),
                if (_allowedMenus.any((key) => key.startsWith('admin_')))
                  _buildDrawerItem(
                    context,
                    IconlyLight.shield_done,
                    "Admin Control",
                    '/admin',
                    currentRoute,
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(height: 1, color: Colors.white24),
                ),

                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, currentMode, _) {
                    IconData icon = Icons.brightness_auto;
                    String text = "System Theme";
                    if (currentMode == ThemeMode.light) {
                      icon = Icons.light_mode;
                      text = "Light Theme";
                    } else if (currentMode == ThemeMode.dark) {
                      icon = Icons.dark_mode;
                      text = "Dark Theme";
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(icon, color: Colors.white70, size: 22),
                        title: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          if (currentMode == ThemeMode.system) {
                            themeNotifier.value = ThemeMode.light;
                          } else if (currentMode == ThemeMode.light) {
                            themeNotifier.value = ThemeMode.dark;
                          } else {
                            themeNotifier.value = ThemeMode.system;
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  IconlyLight.logout,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onTap: _logout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
