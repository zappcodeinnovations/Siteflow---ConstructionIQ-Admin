import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helper.dart';
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

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

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
              required bool isObscured,
              required VoidCallback onToggle,
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
                  IconlyLight.lock,
                  size: 20,
                  color: isDark ? Colors.white70 : const Color(0xFF0D6EFD),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscured ? IconlyLight.hide : IconlyLight.show,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                  onPressed: onToggle,
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
              title: Row(
                children: [
                  const Icon(IconlyLight.lock, color: Color(0xFF0D6EFD), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Change Password",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                    ),
                  ),
                ],
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
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          decoration: buildInputDecoration(
                            label: "Current Password",
                            isObscured: obscureCurrent,
                            onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please enter current password";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          decoration: buildInputDecoration(
                            label: "New Password",
                            isObscured: obscureNew,
                            onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please enter new password";
                            }
                            if (val.trim().length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                          decoration: buildInputDecoration(
                            label: "Confirm New Password",
                            isObscured: obscureConfirm,
                            onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Please confirm new password";
                            }
                            if (val.trim() != newPasswordController.text.trim()) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
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

                          final result = await _controller.changePassword(
                            currentPassword: currentPasswordController.text.trim(),
                            newPassword: newPasswordController.text.trim(),
                            confirmPassword: confirmPasswordController.text.trim(),
                          );

                          if (dialogContext.mounted) {
                            if (result['success'] == true) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message']),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? "Failed to change password"),
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
                          "Update Password",
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

  Widget _buildDetailTile(String label, String value, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162A42) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty || value == 'null' ? "-" : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF0D6EFD), size: 18),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
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
        final shadowColor = isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04);
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
        if (user == null) {
          return const Center(child: Text("No profile data found."));
        }

        final displayName = user.firstName != null && user.lastName != null
            ? "${user.firstName} ${user.lastName}".trim()
            : (user.displayName.isNotEmpty ? user.displayName : (user.email.isNotEmpty ? user.email : "Unknown"));

        final initial = user.initials ?? (displayName.isNotEmpty ? displayName[0].toUpperCase() : "?");

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
                  user.email,
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    user.roleLabel?.isNotEmpty == true
                        ? user.roleLabel!
                        : (user.effectiveRole.isNotEmpty ? user.effectiveRole.toUpperCase() : "SUPER ADMIN"),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D6EFD),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons: Change Password & Edit Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(IconlyLight.lock, size: 16),
                      label: const Text(
                        "Change Password",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(IconlyLight.edit, size: 16, color: Colors.white),
                      label: const Text(
                        "Edit Profile",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Cards Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // 1. Profile Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                                Text(
                                  "Profile Details",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 600;
                                final fullName = user.displayName.isNotEmpty
                                    ? user.displayName
                                    : (user.firstName != null && user.lastName != null
                                        ? "${user.firstName} ${user.lastName}".trim()
                                        : user.email);
                                final username = user.username.isNotEmpty ? user.username : user.email;
                                final mobile = user.phone?.isNotEmpty == true ? user.phone! : "-";
                                final company = user.companyName?.isNotEmpty == true
                                    ? user.companyName!
                                    : "Euroside Construction Limited";
                                final roleType = user.roleLabel?.isNotEmpty == true
                                    ? user.roleLabel!
                                    : (user.effectiveRole.isNotEmpty ? user.effectiveRole : "Super Admin");
                                final accountStatus = user.isActive ? "Active" : "Inactive";
                                final joiningDate = DateHelper.formatToLocal(user.joinedAt);
                                final lastLogin = DateHelper.formatToLocal(user.lastLogin);

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildDetailTile("Full Name", fullName, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Email Address", user.email, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Username", username, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Mobile Number", mobile, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Company Name", company, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Role Type", roleType, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Account Status", accountStatus, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Joining Date", joiningDate, isDark: isDark),
                                      const SizedBox(height: 10),
                                      _buildDetailTile("Last Login", lastLogin, isDark: isDark),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _buildDetailTile("Full Name", fullName, isDark: isDark)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildDetailTile("Email Address", user.email, isDark: isDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildDetailTile("Username", username, isDark: isDark)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildDetailTile("Mobile Number", mobile, isDark: isDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildDetailTile("Company Name", company, isDark: isDark)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildDetailTile("Role Type", roleType, isDark: isDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildDetailTile("Account Status", accountStatus, isDark: isDark)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildDetailTile("Joining Date", joiningDate, isDark: isDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildDetailTile("Last Login", lastLogin, isDark: isDark)),
                                        const SizedBox(width: 12),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Time Display Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                                  Icons.language,
                                  color: Color(0xFF0D6EFD),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Time Display",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Force UK time",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "When on, every page shows UK time (Europe/London) for your account only, no matter where you actually are. Turn it off to go back to time based on your real location.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: true,
                                  activeThumbColor: const Color(0xFF10B981),
                                  onChanged: (val) {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Role & Permissions Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                                  IconlyLight.shield_done,
                                  color: Color(0xFF0D6EFD),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Permissions",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionItem("Full admin dashboard access"),
                            _buildPermissionItem("Manage admins, members, and guests"),
                            _buildPermissionItem("Manage projects, jobs, library, and settings"),
                            _buildPermissionItem("Manage organisation profile and support tickets"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Recent Account Activity
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
                                  IconlyLight.time_circle,
                                  color: Color(0xFF0D6EFD),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Recent Activity",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildActivityItem(
                              IconlyLight.user_1,
                              "Account created",
                              "Initial registration and credentials dispatched",
                              DateHelper.formatToLocal(user.joinedAt),
                              const Color(0xFF0D6EFD),
                            ),
                            _buildActivityItem(
                              IconlyLight.login,
                              "Last login",
                              "Authenticated session via Admin portal",
                              DateHelper.formatToLocal(user.lastLogin),
                              Colors.teal,
                            ),
                            _buildActivityItem(
                              IconlyLight.edit,
                              "Profile last updated",
                              "Profile details and account attributes updated",
                              DateHelper.formatToLocal(user.updatedAt ?? user.lastLogin),
                              Colors.purple.shade400,
                            ),
                            _buildActivityItem(
                              IconlyLight.shield_done,
                              "Password configured",
                              "Secure credentials active and verified",
                              DateHelper.formatToLocal(user.updatedAt ?? user.joinedAt),
                              Colors.green.shade600,
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
