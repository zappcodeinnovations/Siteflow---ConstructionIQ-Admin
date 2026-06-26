import 'package:flutter/material.dart';
import 'admin_announcements_controller.dart';
import 'add_announcement_dialog.dart';
import '../../../core/widgets/shimmer_loading.dart';

class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() => _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  final AdminAnnouncementsController _controller = AdminAnnouncementsController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.fetchNotifications();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        const Text("Announcements", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
        const SizedBox(height: 4),
        Text("Create project announcements for operative users", style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),

        // Filter Bar
        Row(
          children: [
            SizedBox(
              width: 250,
              height: 40,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search announcements",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              child: const Row(
                children: [
                  Text("Active Announcements"),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              onPressed: () {},
              child: const Text("Apply", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
              child: IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() => _searchQuery = "");
                  _controller.fetchNotifications();
                },
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text("Add Announcement", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // List View
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading && _controller.notifications.isEmpty) {
                return const ShimmerLoadingList();
              }

              if (_controller.errorMessage != null && _controller.notifications.isEmpty) {
                return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
              }

              final filtered = _controller.notifications.where((n) =>
                  n.headline.toLowerCase().contains(_searchQuery) ||
                  n.notificationText.toLowerCase().contains(_searchQuery)).toList();

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final notif = filtered[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notif.headline, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2C4A))),
                                  const SizedBox(height: 4),
                                  Text("Audience: ${notif.audience}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (notif.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Text("Active", style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                child: Text("Inactive", style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(notif.notificationText, style: TextStyle(color: Colors.grey.shade800)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${notif.formattedUpdatedAt} • ${notif.updatedByName}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit, size: 14, color: Colors.black87),
                              label: const Text("Edit", style: TextStyle(color: Colors.black87)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
