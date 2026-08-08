import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final foregroundColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return AppBar(
      backgroundColor: appBarColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: foregroundColor)),
      iconTheme: IconThemeData(color: foregroundColor),
      flexibleSpace: ClipRRect(
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: 120,
                  height: 200,
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: -80,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: 80,
                  height: 250,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.01),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        PopupMenuButton<String>(
          icon: Icon(Icons.notifications_outlined, color: foregroundColor),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Text(
                "Notifications",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              enabled: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("No new notifications", style: TextStyle(color: Colors.grey)),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'view_all',
              child: Center(
                child: Text(
                  "View All Notifications",
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view_all') {
              Navigator.pushNamed(context, '/admin');
            }
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}