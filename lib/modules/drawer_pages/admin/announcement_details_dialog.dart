import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/announcement_model.dart';
import 'admin_announcements_controller.dart';
import 'package:intl/intl.dart';

class AnnouncementDetailsDialog extends StatefulWidget {
  final int announcementId;
  final AdminAnnouncementsController controller;

  const AnnouncementDetailsDialog({
    super.key,
    required this.announcementId,
    required this.controller,
  });

  @override
  State<AnnouncementDetailsDialog> createState() => _AnnouncementDetailsDialogState();
}

class _AnnouncementDetailsDialogState extends State<AnnouncementDetailsDialog> {
  Announcement? announcement;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final fetched = await widget.controller.fetchAnnouncementDetails(widget.announcementId);
    if (mounted) {
      setState(() {
        announcement = fetched;
        isLoading = false;
      });
    }
  }

  Color _getIconColor(int id) {
    final colors = [const Color(0xFF0F2C4A), const Color(0xFF0D6EFD), Colors.purple, Colors.teal, Colors.indigo];
    return colors[id % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: Colors.white24) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: isLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0D6EFD))),
              )
            : announcement == null
                ? SizedBox(
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(IconlyLight.danger, color: Colors.red, size: 56),
                        const SizedBox(height: 16),
                        Text("Oops!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 8),
                        Text("Failed to load announcement details.", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF162A42) : Colors.grey.shade200,
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with Icon
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF071C2D) : const Color(0xFF0F2C4A), // Deep navy
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(IconlyLight.close_square, color: Colors.white70),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 50),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF0F2C4A) : Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: isDark
                                    ? _getIconColor(announcement!.id).withValues(alpha: 0.25)
                                    : _getIconColor(announcement!.id).withValues(alpha: 0.1),
                                child: Icon(IconlyLight.notification, color: isDark ? Colors.white : _getIconColor(announcement!.id), size: 40),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Title and Status
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            announcement!.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: announcement!.isActive
                                ? (isDark ? Colors.green.shade900.withValues(alpha: 0.35) : Colors.green.shade50)
                                : (isDark ? Colors.red.shade900.withValues(alpha: 0.35) : Colors.red.shade50),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: announcement!.isActive
                                  ? (isDark ? Colors.green.shade700.withValues(alpha: 0.6) : Colors.green.shade200)
                                  : (isDark ? Colors.red.shade700.withValues(alpha: 0.6) : Colors.red.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: announcement!.isActive ? Colors.greenAccent : Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                announcement!.isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: announcement!.isActive
                                      ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                      : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info Sections
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("Message", isDark),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF162A42) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                                ),
                                child: Text(
                                  announcement!.message,
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87, height: 1.5),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              _buildSectionTitle("Details", isDark),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.folder, "Project", announcement!.projectName.isNotEmpty ? announcement!.projectName : "General / All Projects", isDark),
                                _buildInfoRow(IconlyLight.user_1, "Author", announcement!.createdByName, isDark),
                                if (announcement!.createdAt.isNotEmpty)
                                  _buildInfoRow(IconlyLight.calendar, "Published On", _formatDate(announcement!.createdAt), isDark),
                              ], isDark),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162A42) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: isDark ? Border.all(color: Colors.white12) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(icon, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0D6EFD), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
