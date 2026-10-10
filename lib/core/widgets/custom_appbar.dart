import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../models/admin_notification_model.dart';
import '../../modules/drawer_pages/admin/admin_notifications_controller.dart';
import '../../modules/drawer_pages/admin_screen.dart';
import '../services/auth_service.dart';
import '../utils/date_helper.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final AdminNotificationsController _controller =
      AdminNotificationsController();
  bool _canViewNotifications = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _loadNotificationAccess();
  }

  Future<void> _loadNotificationAccess() async {
    final allowed = await AuthService.can('admin_notifications');
    if (!mounted) return;
    setState(() => _canViewNotifications = allowed);
    if (allowed) await _controller.fetchNotifications();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? AppTheme.darkSurface : Colors.white;
    final foregroundColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    final recent = _controller.notifications
        .where((n) => n.isActive)
        .take(5)
        .toList();

    return AppBar(
      backgroundColor: appBarColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      title: Text(
        widget.title,
        style: TextStyle(fontWeight: FontWeight.bold, color: foregroundColor),
      ),
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
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.02),
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
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.01),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.actions != null) ...widget.actions!,
        if (_canViewNotifications)
          PopupMenuButton<String>(
            color: isDark ? const Color(0xFF172433) : Colors.white,
            icon: Badge(
              isLabelVisible: recent.isNotEmpty,
              label: Text('${recent.length}'),
              child: Icon(Icons.notifications_outlined, color: foregroundColor),
            ),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  "Notifications",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              if (_controller.isLoading)
                const PopupMenuItem(
                  enabled: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                )
              else if (recent.isEmpty)
                const PopupMenuItem(
                  enabled: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "No new notifications",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recent.map(
                  (n) => PopupMenuItem(
                    enabled: false,
                    child: _NotificationRow(notification: n, isDark: isDark),
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'view_all',
                child: Center(
                  child: Text(
                    "View All Notifications",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'view_all') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminScreen(
                      initialMenuKey: 'admin_notifications',
                    ),
                  ),
                );
              }
            },
          ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AdminNotification notification;
  final bool isDark;

  const _NotificationRow({required this.notification, required this.isDark});

  // Prefer sent_at (when the push actually went out); fall back to
  // created_at for notifications that haven't been sent yet. Both are
  // UTC-aware ISO timestamps from the backend - DateHelper.formatToLocal()
  // converts to the device's own local timezone, matching how the full
  // Notifications screen already formats this same data.
  String get _timestampLabel {
    final raw = notification.sentAt.isNotEmpty ? notification.sentAt : notification.createdAt;
    if (raw.trim().isEmpty) return '';
    final formatted = DateHelper.formatToLocal(raw, includeTime: true);
    return (formatted == '-' || formatted.isEmpty) ? '' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = _timestampLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.headline,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            notification.notificationText,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              timestamp,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
