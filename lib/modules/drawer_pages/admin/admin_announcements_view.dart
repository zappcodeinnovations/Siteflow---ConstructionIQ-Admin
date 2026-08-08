import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/announcement_model.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/theme/app_theme.dart';
import 'admin_announcements_controller.dart';
import 'add_announcement_dialog.dart';
import 'edit_announcement_dialog.dart';
import 'announcement_details_dialog.dart';

class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() => _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  final AdminAnnouncementsController _controller =
      AdminAnnouncementsController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.fetchAnnouncements();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAnnouncementDialog(controller: _controller),
    );
  }

  void _deleteAnnouncement(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: Text(
          "Are you sure you want to remove '${announcement.title}'?",
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
              final result = await _controller.deleteAnnouncement(
                announcement.id,
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

  void _editAnnouncement(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) => EditAnnouncementDialog(
        announcement: announcement,
        controller: _controller,
      ),
    );
  }

  Color _getIconColor(int id) {
    final colors = [
      const Color(0xFF0F2C4A),
      const Color(0xFF0D6EFD),
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[id % colors.length];
  }

  Widget _buildAnnouncementCard(
    Announcement announcement, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final iconColor = _getIconColor(announcement.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Dismiss",
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) {
                return AnnouncementDetailsDialog(
                  announcementId: announcement.id,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            IconlyLight.notification,
                            color: iconColor,
                          ),
                        ),
                        if (announcement.isActive)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            announcement.message,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        IconlyLight.more_circle,
                        color: Colors.grey,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') _editAnnouncement(announcement);
                        if (val == 'delete') _deleteAnnouncement(announcement);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("Edit Announcement"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            "Delete Announcement",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PROJECT",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          announcement.projectName.isNotEmpty
                              ? announcement.projectName
                              : "General",
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "AUTHOR",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          announcement.createdByName,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final headerBg = isDark ? AppTheme.corporateBlue : Colors.grey.shade50;
    final headerTitle = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final searchFillColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.corporateBlue : null,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final filteredAnnouncements = _controller.announcements
              .where(
                (a) =>
                    a.title.toLowerCase().contains(_searchQuery) ||
                    a.projectName.toLowerCase().contains(_searchQuery) ||
                    a.message.toLowerCase().contains(_searchQuery),
              )
              .toList();

          final totalAnnouncements = _controller.announcements.length;

          return Column(
            children: [
              // Header & Search
              Container(
                color: headerBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Announcements",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: headerTitle,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$totalAnnouncements Total",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _showAddDialog,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6EFD),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0D6EFD,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              IconlyLight.plus,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Search announcements...",
                        hintStyle: TextStyle(color: subtitleColor),
                        prefixIcon: Icon(
                          IconlyLight.search,
                          color: subtitleColor,
                        ),
                        filled: true,
                        fillColor: searchFillColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ],
                ),
              ),

              // Announcements List
              Expanded(
                child:
                    _controller.isLoading && _controller.announcements.isEmpty
                    ? const ShimmerLoadingList()
                    : _controller.errorMessage != null &&
                          _controller.announcements.isEmpty
                    ? Center(
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAnnouncements.length,
                        itemBuilder: (context, index) {
                          return _buildAnnouncementCard(
                            filteredAnnouncements[index],
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
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
