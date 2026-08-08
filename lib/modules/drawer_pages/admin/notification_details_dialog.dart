import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/admin_notification_model.dart';
import 'admin_notifications_controller.dart';

class NotificationDetailsDialog extends StatefulWidget {
  final int notificationId;
  final AdminNotificationsController controller;

  const NotificationDetailsDialog({
    super.key,
    required this.notificationId,
    required this.controller,
  });

  @override
  State<NotificationDetailsDialog> createState() => _NotificationDetailsDialogState();
}

class _NotificationDetailsDialogState extends State<NotificationDetailsDialog> {
  AdminNotification? notification;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final fetched = await widget.controller.fetchNotificationDetails(widget.notificationId);
    if (mounted) {
      setState(() {
        notification = fetched;
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
            : notification == null
                ? SizedBox(
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(IconlyLight.danger, color: Colors.red, size: 56),
                        const SizedBox(height: 16),
                        const Text("Oops!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        const Text("Failed to load notification details.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
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
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F2C4A), // Deep navy
                                borderRadius: BorderRadius.only(
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: _getIconColor(notification!.id).withValues(alpha: 0.1),
                                child: Icon(IconlyLight.notification, color: _getIconColor(notification!.id), size: 40),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Title and Status
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            notification!.headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: notification!.isActive ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: notification!.isActive ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: notification!.isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                notification!.isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: notification!.isActive ? Colors.green.shade700 : Colors.red.shade700,
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
                              _buildSectionTitle("Message"),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  notification!.notificationText,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              _buildSectionTitle("Audience & Push"),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.user_1, "Audience", notification!.audience),
                                _buildInfoRow(IconlyLight.category, "Operator IDs", notification!.operatorIds.isEmpty ? "None" : notification!.operatorIds.join(', ')),
                                _buildInfoRow(IconlyLight.send, "Push Success", "${notification!.fcmSuccessCount} / ${notification!.fcmSuccessCount + notification!.fcmFailureCount}"),
                              ]),
                              
                              const SizedBox(height: 20),
                              
                              _buildSectionTitle("Details"),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.profile, "Author", notification!.createdByName),
                                if (notification!.formattedUpdatedAt.isNotEmpty)
                                  _buildInfoRow(IconlyLight.calendar, "Updated At", notification!.formattedUpdatedAt),
                              ]),
                              
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Icon(icon, color: const Color(0xFF0D6EFD), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
