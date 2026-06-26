import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

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
    final iconColor = isActive ? const Color(0xFF0D6EFD) : Colors.grey.shade600;
    final textColor = isActive ? const Color(0xFF0F2C4A) : Colors.grey.shade800;
    final bgColor = isActive
        ? const Color(0xFF0D6EFD).withValues(alpha: 0.08)
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
            Navigator.pushNamedAndRemoveUntil(context, route, ModalRoute.withName('/home'));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern Deep Navy Header
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2C4A), // Deep Navy
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
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
                _buildDrawerItem(
                  context,
                  Icons.work_outline,
                  "Job Sheet",
                  '/jobSheet',
                  currentRoute,
                ),
                _buildDrawerItem(
                  context,
                  Icons.bar_chart_outlined,
                  "Productivity",
                  '/productivity',
                  currentRoute,
                ),
                _buildDrawerItem(
                  context,
                  Icons.access_time_outlined,
                  "Timesheet",
                  '/timesheet',
                  currentRoute,
                ),
                _buildDrawerItem(
                  context,
                  Icons.admin_panel_settings_outlined,
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
                      color: Colors.grey.shade400,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                _buildDrawerItem(
                  context,
                  Icons.settings_outlined,
                  "Settings",
                  '/settings',
                  currentRoute,
                ),
                _buildDrawerItem(
                  context,
                  Icons.security_outlined,
                  "Admin Control",
                  '/admin',
                  currentRoute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
