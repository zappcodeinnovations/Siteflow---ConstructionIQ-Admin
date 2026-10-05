import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/admin_guest_model.dart';
import 'admin_guests_controller.dart';
import 'package:intl/intl.dart';

class GuestDetailsDialog extends StatefulWidget {
  final int guestId;
  final AdminGuestsController controller;

  const GuestDetailsDialog({
    super.key,
    required this.guestId,
    required this.controller,
  });

  @override
  State<GuestDetailsDialog> createState() => _GuestDetailsDialogState();
}

class _GuestDetailsDialogState extends State<GuestDetailsDialog> {
  AdminGuest? guest;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final fetchedGuest = await widget.controller.fetchGuestDetails(widget.guestId);
    if (mounted) {
      setState(() {
        guest = fetchedGuest;
        isLoading = false;
      });
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [const Color(0xFF0F2C4A), const Color(0xFF0D6EFD), const Color(0xFF6C757D), Colors.teal, Colors.indigo];
    int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
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
            : guest == null
                ? SizedBox(
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(IconlyLight.danger, color: Colors.red, size: 56),
                        const SizedBox(height: 16),
                        Text("Oops!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 8),
                        Text("Failed to load guest details.", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
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
                        // Header with Avatar
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
                                backgroundColor: _getAvatarColor(guest!.displayName),
                                child: Text(
                                  guest!.displayName.isNotEmpty ? guest!.displayName.substring(0, 2).toUpperCase() : "G",
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Name and Status
                        Text(
                          guest!.displayName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: guest!.isActive
                                ? (isDark ? Colors.green.shade900.withValues(alpha: 0.35) : Colors.green.shade50)
                                : (isDark ? Colors.red.shade900.withValues(alpha: 0.35) : Colors.red.shade50),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: guest!.isActive
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
                                  color: guest!.isActive ? Colors.greenAccent : Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                guest!.isActive ? "Active Guest" : "Inactive Guest",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: guest!.isActive
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
                              _buildSectionTitle("Contact Information", isDark),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.message, "Email", guest!.email, isDark),
                                _buildInfoRow(IconlyLight.call, "Phone", guest!.phone.isNotEmpty ? guest!.phone : "N/A", isDark),
                              ], isDark),
                              
                              const SizedBox(height: 20),
                              
                              _buildSectionTitle("Account Details", isDark),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.user_1, "Username", guest!.username, isDark),
                                if (guest!.createdAt.isNotEmpty)
                                  _buildInfoRow(IconlyLight.calendar, "Invited On", _formatDate(guest!.createdAt), isDark),
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
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
