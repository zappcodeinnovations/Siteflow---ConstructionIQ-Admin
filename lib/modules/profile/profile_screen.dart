import 'package:flutter/material.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'profile_controller.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _controller.fetchProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    final user = _controller.profile;
    if (user == null) return;

    final firstNameController = TextEditingController(text: user.firstName ?? '');
    final lastNameController = TextEditingController(text: user.lastName ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: "First Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: "Last Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: "Mobile Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final success = await _controller.updateProfile({
                  'first_name': firstNameController.text.trim(),
                  'last_name': lastNameController.text.trim(),
                  'phone': phoneController.text.trim(),
                });
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_controller.errorMessage ?? "Failed to update profile")),
                  );
                }
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty || value == 'null' ? "-" : value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) return const ShimmerLoadingDashboard();
        if (_controller.errorMessage != null && _controller.profile == null) {
          return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
        }

        final user = _controller.profile;
        if (user == null) return const Center(child: Text("No profile data found."));

        final displayName = user.firstName != null && user.lastName != null 
            ? "${user.firstName} ${user.lastName}"
            : (user.displayName ?? user.email ?? "Unknown");

        final initial = user.initials ?? (displayName.isNotEmpty ? displayName[0].toUpperCase() : "?");

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header section with Gradient and Avatar
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F2C4A), Color(0xFF0D6EFD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                              child: user.profileImageUrl == null
                                  ? Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey))
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                
                // Name & Role
                Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(user.email ?? "", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Text((user.roleLabel ?? user.effectiveRole ?? "User").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _showEditProfileDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D6EFD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  ),
                  child: const Text("Edit Profile", style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),

                // Cards Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Personal Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline, color: Color(0xFF0D6EFD), size: 20),
                                const SizedBox(width: 8),
                                const Text("Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: _buildInfoRow("First Name", user.firstName ?? "")),
                                Expanded(child: _buildInfoRow("Last Name", user.lastName ?? "")),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            _buildInfoRow("Email Address", user.email ?? ""),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            _buildInfoRow("Mobile Number", user.phone ?? ""),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            _buildInfoRow("Preferred Language", "English (United Kingdom)"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role & Permissions Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: Color(0xFF0D6EFD), size: 20),
                                const SizedBox(width: 8),
                                const Text("Role & Permissions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: const Text("Level 4", style: TextStyle(fontSize: 11, color: Color(0xFF0D6EFD), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildPermissionItem("Manage Users & Teams"),
                            _buildPermissionItem("View Global Financial Reports"),
                            _buildPermissionItem("Approve & Edit Timesheets"),
                            _buildPermissionItem("Resource Scheduling Access"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent Account Activity
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Color(0xFF0D6EFD), size: 20),
                                const SizedBox(width: 8),
                                const Text("Recent Account Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Activity Timeline Custom Layout
                            _buildActivityItem(
                              Icons.login, 
                              "Clocked into System", 
                              "Access via Mobile Device - IP 192.168.1.1", 
                              "Today, 08:45 AM",
                              const Color(0xFF0D6EFD)
                            ),
                            _buildActivityItem(
                              Icons.edit_document, 
                              "Updated Job Sheet #003", 
                              "Modified project milestones and allocation", 
                              "Yesterday, 04:20 PM",
                              Colors.purple.shade400
                            ),
                            _buildActivityItem(
                              Icons.security, 
                              "Security Settings Changed", 
                              "2FA authentication method updated", 
                              "3 days ago, 10:15 AM",
                              Colors.grey.shade600
                            ),
                            
                            const Divider(),
                            Center(
                              child: TextButton(
                                onPressed: () {},
                                child: const Text("View Full Audit Log", style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
