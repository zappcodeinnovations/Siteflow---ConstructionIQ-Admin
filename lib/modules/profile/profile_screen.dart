import 'package:flutter/material.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'profile_controller.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../drawer_pages/admin/admin_activity_logs_view.dart';

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

    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: user.firstName ?? '');
    final lastNameController = TextEditingController(text: user.lastName ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            InputDecoration buildInputDecoration({
              required String label,
              required IconData icon,
            }) {
              return InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 14,
                ),
                floatingLabelStyle: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0D6EFD),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF0D6EFD),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D6EFD),
                    width: 1.8,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade200,
                ),
              ),
              title: Text(
                "Edit Profile",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width > 400 ? 360 : double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: firstNameController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          decoration: buildInputDecoration(
                            label: "First Name",
                            icon: IconlyLight.profile,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please enter first name";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: lastNameController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          decoration: buildInputDecoration(
                            label: "Last Name",
                            icon: IconlyLight.profile,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please enter last name";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          decoration: buildInputDecoration(
                            label: "Mobile Number",
                            icon: IconlyLight.call,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final success = await _controller.updateProfile({
                            'first_name': firstNameController.text.trim(),
                            'last_name': lastNameController.text.trim(),
                            'phone': phoneController.text.trim(),
                          });

                          if (dialogContext.mounted) {
                            if (success) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Profile updated successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _controller.errorMessage ?? "Failed to update profile",
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
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
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty || value == 'null' ? "-" : value,
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(IconlyLight.category, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
        final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
        
        if (_controller.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (_controller.errorMessage != null && _controller.profile == null) {
          return Center(
            child: Text(
              _controller.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final user = _controller.profile;
        if (user == null)
          return const Center(child: Text("No profile data found."));

        final displayName = user.firstName != null && user.lastName != null
            ? "${user.firstName} ${user.lastName}"
            : (user.displayName ?? user.email ?? "Unknown");

        final initial =
            user.initials ??
            (displayName.isNotEmpty ? displayName[0].toUpperCase() : "?");

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8F9FA),
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
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 16,
                              height: 16,
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
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Name & Role
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "",
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (user.roleLabel ?? user.effectiveRole ?? "User")
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _showEditProfileDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D6EFD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Color(0xFF0D6EFD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  IconlyLight.profile,
                                  color: Color(0xFF0D6EFD),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Personal Details",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    "First Name",
                                    user.firstName ?? "",
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    "Last Name",
                                    user.lastName ?? "",
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildInfoRow("Email Address", user.email ?? ""),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildInfoRow("Mobile Number", user.phone ?? ""),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildInfoRow(
                              "Preferred Language",
                              "English (United Kingdom)",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role & Permissions Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  IconlyLight.category,
                                  color: Color(0xFF0D6EFD),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Role & Permissions",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Level 4",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0D6EFD),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildPermissionItem("Manage Users & Teams"),
                            _buildPermissionItem(
                              "View Global Financial Reports",
                            ),
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
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  IconlyLight.category,
                                  color: Color(0xFF0D6EFD),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Recent Account Activity",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Activity Timeline Custom Layout
                            _buildActivityItem(
                              IconlyLight.category,
                              "Clocked into System",
                              "Access via Mobile Device - IP 192.168.1.1",
                              "Today, 08:45 AM",
                              const Color(0xFF0D6EFD),
                            ),
                            _buildActivityItem(
                              IconlyLight.category,
                              "Updated Job Sheet #003",
                              "Modified project milestones and allocation",
                              "Yesterday, 04:20 PM",
                              Colors.purple.shade400,
                            ),
                            _buildActivityItem(
                              IconlyLight.category,
                              "Security Settings Changed",
                              "2FA authentication method updated",
                              "3 days ago, 10:15 AM",
                              Colors.grey.shade600,
                            ),

                            const Divider(),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminActivityLogsView()),
                                  );
                                },
                                child: const Text(
                                  "View Full Audit Log",
                                  style: TextStyle(
                                    color: Color(0xFF0D6EFD),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
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
