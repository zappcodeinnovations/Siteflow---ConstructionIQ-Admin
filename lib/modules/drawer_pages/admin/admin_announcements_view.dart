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
  final AdminAnnouncementsController _controller = AdminAnnouncementsController();

  final TextEditingController _searchController = TextEditingController();
  String _appliedSearchQuery = "";
  String _selectedStatusFilter = "Active Announcements";
  String _appliedStatusFilter = "Active Announcements";

  final List<String> _statusFilterOptions = [
    "Active Announcements",
    "All Announcements",
    "Inactive Announcements",
  ];

  @override
  void initState() {
    super.initState();
    _controller.fetchAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _appliedSearchQuery = _searchController.text.trim().toLowerCase();
      _appliedStatusFilter = _selectedStatusFilter;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _appliedSearchQuery = "";
      _selectedStatusFilter = "Active Announcements";
      _appliedStatusFilter = "Active Announcements";
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              transitionBuilder: (context, animation, secondaryAnimation, child) {
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
                // Top row: Title + Active chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        IconlyLight.notification,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (announcement.projectName.isNotEmpty)
                            Text(
                              "${announcement.projectName}${announcement.projectCode.isNotEmpty ? ' (${announcement.projectCode})' : ''}${announcement.clientName.isNotEmpty ? ' · ${announcement.clientName}' : ''}",
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: announcement.isActive
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        announcement.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: announcement.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Message snippet
                if (announcement.message.isNotEmpty)
                  Text(
                    announcement.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 10),
                // Bottom row: Updated info + Edit Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Updated ${announcement.updatedAt.isNotEmpty ? announcement.updatedAt : announcement.createdAt}${announcement.updatedByName.isNotEmpty ? ' · ${announcement.updatedByName}' : (announcement.createdByName.isNotEmpty ? ' · ${announcement.createdByName}' : '')}",
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _editAnnouncement(announcement),
                      icon: const Icon(IconlyLight.edit, size: 14),
                      label: const Text(
                        "Edit",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D6EFD),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    final cardColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final headerBg = isDark ? AppTheme.darkSurface : Colors.white;
    final headerTitle = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF2C3E50) : Colors.grey.shade300;
    final searchFillColor = isDark ? const Color(0xFF152232) : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final filteredAnnouncements = _controller.announcements.where((a) {
            // Search text match
            if (_appliedSearchQuery.isNotEmpty) {
              final query = _appliedSearchQuery;
              final match = a.title.toLowerCase().contains(query) ||
                  a.projectName.toLowerCase().contains(query) ||
                  a.message.toLowerCase().contains(query);
              if (!match) return false;
            }

            // Status filter match
            if (_appliedStatusFilter == "Active Announcements") {
              if (!a.isActive) return false;
            } else if (_appliedStatusFilter == "Inactive Announcements") {
              if (a.isActive) return false;
            }
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Structured Filter Toolbar
              Container(
                color: headerBg,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Announcements",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Create project announcements for operative users",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Toolbar Row 1: Search announcements
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Search announcements...",
                        hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                        prefixIcon: Icon(
                          IconlyLight.search,
                          color: subtitleColor,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: searchFillColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
                        ),
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                    const SizedBox(height: 10),

                    // Filter Toolbar Row 2: Status Dropdown, Apply, Reset, + Add Announcement
                    Row(
                      children: [
                        // Status filter dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatusFilter,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: searchFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor, fontSize: 12),
                            items: _statusFilterOptions.map((opt) {
                              return DropdownMenuItem(
                                value: opt,
                                child: Text(
                                  opt,
                                  style: TextStyle(color: textColor, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatusFilter = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Apply button
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Reset button
                        IconButton(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh, size: 20),
                          color: subtitleColor,
                          style: IconButton.styleFrom(
                            backgroundColor: searchFillColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: borderColor),
                            ),
                            padding: const EdgeInsets.all(10),
                          ),
                          tooltip: "Reset Filters",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // + Add Announcement button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(IconlyLight.plus, size: 16, color: Colors.white),
                        label: const Text(
                          "Add Announcement",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: borderColor, height: 1),

              // Announcements List
              Expanded(
                child: _controller.isLoading && _controller.announcements.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _controller.errorMessage != null && _controller.announcements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _controller.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _controller.fetchAnnouncements,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : filteredAnnouncements.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        IconlyLight.notification,
                                        size: 48,
                                        color: subtitleColor.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "No announcements found",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Try adjusting your search or filters.",
                                        style: TextStyle(
                                          color: subtitleColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _controller.fetchAnnouncements,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
