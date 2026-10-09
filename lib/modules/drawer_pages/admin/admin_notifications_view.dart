import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/admin_notification_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helper.dart';
import 'admin_notifications_controller.dart';
import 'add_notification_dialog.dart';
import 'edit_notification_dialog.dart';
import 'notification_details_dialog.dart';
import '../../../../core/services/auth_service.dart';

class AdminNotificationsView extends StatefulWidget {
  const AdminNotificationsView({super.key});

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  final AdminNotificationsController _controller =
      AdminNotificationsController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedAudience = "all_notifications";
  String _appliedSearch = "";
  String _appliedAudience = "all_notifications";

  bool _canCreate = false;
  bool _canEdit = false;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final access = await Future.wait([
      AuthService.can('admin_notifications', action: 'create'),
      AuthService.can('admin_notifications', action: 'edit'),
      AuthService.can('admin_notifications', action: 'delete'),
    ]);
    if (!mounted) return;
    setState(() {
      _canCreate = access[0];
      _canEdit = access[1];
      _canDelete = access[2];
    });
    await _controller.fetchNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      _appliedSearch = _searchController.text.trim().toLowerCase();
      _appliedAudience = _selectedAudience;
    });
  }

  void _resetFilter() {
    setState(() {
      _searchController.clear();
      _selectedAudience = "all_notifications";
      _appliedSearch = "";
      _appliedAudience = "all_notifications";
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNotificationDialog(controller: _controller),
    );
  }

  void _deleteNotification(AdminNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Notification"),
        content: Text(
          "Are you sure you want to remove '${notification.headline}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final result = await _controller.deleteNotification(
                notification.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editNotification(AdminNotification notification) {
    showDialog(
      context: context,
      builder: (context) => EditNotificationDialog(
        notification: notification,
        controller: _controller,
      ),
    );
  }

  String _formatSentTimestamp(AdminNotification notification) {
    final rawDate = notification.sentAt.isNotEmpty
        ? notification.sentAt
        : notification.createdAt;
    if (rawDate.trim().isEmpty) return '';
    final formatted = DateHelper.formatToLocal(rawDate, includeTime: true);
    if (formatted == '-' || formatted.isEmpty) return '';

    if (formatted.contains(' ') && !formatted.contains(', ')) {
      final parts = formatted.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0];
        final timePart = parts.sublist(1).join(' ');
        return 'Sent $datePart, $timePart';
      }
    }
    return 'Sent $formatted';
  }

  String _formatAudienceBadge(String rawAudience) {
    final clean = rawAudience.toLowerCase().trim();
    if (clean == 'all_admins' || clean == 'admins') {
      return 'All admins';
    } else if (clean == 'all_operators' || clean == 'all') {
      return 'All operators';
    } else if (clean == 'selected_operators') {
      return 'Selected operators';
    } else if (clean.isEmpty) {
      return 'All admins';
    }
    return rawAudience.replaceAll('_', ' ');
  }

  String _formatDeliveryStatus(AdminNotification notification) {
    final clean = notification.audience.toLowerCase().trim();
    String target = 'all admins and managers';
    if (clean == 'all_operators' || clean == 'all') {
      target = 'all operators';
    } else if (clean == 'selected_operators') {
      target = 'selected operators';
    } else if (clean == 'all_admins' || clean == 'admins') {
      target = 'all admins and managers';
    }
    return 'Sent to $target - Push sent ${notification.fcmSuccessCount}, failed ${notification.fcmFailureCount}';
  }

  Widget _buildNotificationCard(
    AdminNotification notification, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    final sentTimestamp = _formatSentTimestamp(notification);
    final audienceBadge = _formatAudienceBadge(notification.audience);
    final deliveryStatus = _formatDeliveryStatus(notification);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Dismiss",
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) {
                return NotificationDetailsDialog(
                  notificationId: notification.id,
                  controller: _controller,
                );
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Date (Left) and Audience Badge (Right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.headline,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          if (sentTimestamp.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              sentTimestamp,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                            : const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        audienceBadge,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Message Body
                Text(
                  notification.notificationText,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // Bottom Row: Delivery summary + Actions (Delete/Edit)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deliveryStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_canEdit)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _editNotification(notification),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    if (_canDelete)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _deleteNotification(notification),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.withValues(alpha: 0.2)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.red.shade300
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final headerBg = isDark ? AppTheme.darkSurfaceRaised : Colors.grey.shade50;
    final headerTitle = isDark ? AppTheme.darkText : const Color(0xFF0F2C4A);
    final textColor = isDark ? AppTheme.darkText : Colors.black87;
    final subtitleColor = isDark ? AppTheme.darkMuted : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final searchFillColor = isDark
        ? AppTheme.darkSurface
        : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : null,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final filtered = _controller.notifications.where((a) {
            if (_appliedSearch.isNotEmpty) {
              final matchesSearch = a.headline
                      .toLowerCase()
                      .contains(_appliedSearch) ||
                  a.notificationText.toLowerCase().contains(_appliedSearch) ||
                  a.audience.toLowerCase().contains(_appliedSearch) ||
                  a.createdByName.toLowerCase().contains(_appliedSearch);
              if (!matchesSearch) return false;
            }

            if (_appliedAudience == "all_operators") {
              final aud = a.audience.toLowerCase();
              return aud == "all_operators" || aud == "all" || a.isForAllOperators;
            } else if (_appliedAudience == "selected_operators") {
              final aud = a.audience.toLowerCase();
              return aud == "selected_operators";
            } else if (_appliedAudience == "all_admins") {
              final aud = a.audience.toLowerCase();
              return aud == "all_admins" || aud == "admins";
            }

            return true;
          }).toList();

          return Column(
            children: [
              // Header, Action & Filter Bar
              Container(
                color: headerBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row with Title & Prominent + Send Notification Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Notifications",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: headerTitle,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Send updates to one operator or all operators",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_canCreate) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "+ Send Notification",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Row: Search Field
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Search notifications",
                        hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                        prefixIcon: Icon(
                          IconlyLight.search,
                          color: subtitleColor,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: searchFillColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0D6EFD),
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _applyFilter(),
                    ),
                    const SizedBox(height: 10),

                    // Filter Controls: Dropdown + Apply + Reset
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: searchFillColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedAudience,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: subtitleColor,
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: "all_notifications",
                                    child: Text("All Notifications"),
                                  ),
                                  DropdownMenuItem(
                                    value: "all_operators",
                                    child: Text("All Operators"),
                                  ),
                                  DropdownMenuItem(
                                    value: "selected_operators",
                                    child: Text("Selected Operators"),
                                  ),
                                  DropdownMenuItem(
                                    value: "all_admins",
                                    child: Text("All Admins"),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedAudience = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            minimumSize: const Size(64, 38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: searchFillColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: subtitleColor,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: "Reset",
                            onPressed: _resetFilter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child:
                    _controller.isLoading && _controller.notifications.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _controller.errorMessage != null &&
                                _controller.notifications.isEmpty
                            ? Center(
                                child: Text(
                                  _controller.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      "No notifications found.",
                                      style: TextStyle(color: subtitleColor),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _buildNotificationCard(
                                        filtered[index],
                                        cardColor: cardColor,
                                        borderColor: borderColor,
                                        textColor: textColor,
                                        subtitleColor: subtitleColor,
                                        isDark: isDark,
                                      );
                                    },
                                  ),
              ),
            ],
          );
        },
      ),
    );
  }
}
