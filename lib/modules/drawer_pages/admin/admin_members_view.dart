import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../models/admin_member_model.dart';
import 'admin_members_controller.dart';
import 'edit_member_dialog.dart';
import 'invite_member_dialog.dart';
import 'member_details_dialog.dart';
import 'qualifications_dialog.dart';

class AdminMembersView extends StatefulWidget {
  const AdminMembersView({super.key});

  @override
  State<AdminMembersView> createState() => _AdminMembersViewState();
}

class _AdminMembersViewState extends State<AdminMembersView> {
  final AdminMembersController _controller = AdminMembersController();
  final TextEditingController _searchFieldController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.fetchMembers();
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchFieldController.clear();
    });
    _controller.setRoleFilter('all');
    _controller.setStatusFilter('active');
  }

  Future<void> _exportMembers() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exporting members..."), duration: Duration(seconds: 2)),
      );
      var url = '${ApiEndpoints.baseUrl}/admin/members/export/?status=${_controller.statusFilter}';
      if (_controller.roleFilter != 'all') url += '&role=${_controller.roleFilter}';
      if (_searchQuery.isNotEmpty) url += '&search=${Uri.encodeQueryComponent(_searchQuery)}';
      final response = await ApiClient.get(url);
      if (!mounted) return;
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/members_export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await Share.shareXFiles([XFile(file.path)], text: "Members Export");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to export (${response.statusCode}).")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error exporting members: $e")),
        );
      }
    }
  }

  Future<void> _showImportMembersDialog() async {
    PlatformFile? pickedFile;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Import Members from Excel"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: isSubmitting ? null : () => _controller.downloadImportTemplate(),
                  icon: const Icon(IconlyLight.download, size: 16),
                  label: const Text("Download Template"),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xlsx'],
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setDialogState(() => pickedFile = result.files.first);
                          }
                        },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text("Choose .xlsx File"),
                ),
                const SizedBox(height: 6),
                Text(pickedFile?.name ?? "No file chosen", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: (isSubmitting || pickedFile?.path == null)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final result = await _controller.importMembersExcel(pickedFile!.path!);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        final data = result['data'] as Map<String, dynamic>?;
                        final errors = (data?['errors'] as List?) ?? [];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errors.isNotEmpty ? "${result['message']} ${errors.length} row(s) skipped." : result['message'] ?? ''),
                            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Import"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteMemberDialog(controller: _controller),
    );
  }

  void _showEditDialog(AdminMember member) {
    showDialog(
      context: context,
      builder: (context) => EditMemberDialog(controller: _controller, member: member),
    );
  }

  void _showMemberDetails(AdminMember member) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MemberDetailsDialog(
          memberId: member.id,
          controller: _controller,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(AdminMember member) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Change Password for ${member.displayName}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "The password is not shown anywhere in the admin panel after saving.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: "New Password",
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscure,
                decoration: const InputDecoration(labelText: "Confirm Password"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;
                if (newPassword.isEmpty || confirmPassword.isEmpty) return;
                Navigator.pop(dialogContext);
                final result = await _controller.changePassword(
                  member.id,
                  newPassword: newPassword,
                  confirmPassword: confirmPassword,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmConvertToGuest(AdminMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Convert to Guest"),
        content: Text("Convert ${member.displayName} to a guest user? They will lose member access."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Convert", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _controller.convertToGuest(member.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  void _showQualificationsDialog(AdminMember member) {
    showDialog(
      context: context,
      builder: (dialogContext) => QualificationsDialog(member: member, controller: _controller),
    );
  }

  void _deleteMember(AdminMember member) {
    final isPending = _controller.statusFilter == 'pending';
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isPending ? "Revoke Invitation" : "Delete Member"),
        content: Text(
          isPending
              ? "Are you sure you want to revoke the invitation for ${member.email}?"
              : "Are you sure you want to remove ${member.email}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await _controller.deleteMember(member.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Action completed.'),
                  backgroundColor: result['success'] == true
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
            child: Text(
              isPending ? "Revoke" : "Delete",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resendInvite(AdminMember member) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller.resendInvite(member.id, email: member.email);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Invitation resent.'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  void _copyInviteLink(AdminMember member) {
    Clipboard.setData(ClipboardData(text: member.email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Member email copied to clipboard."),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0F2C4A), // Dark navy
      const Color(0xFF0D6EFD), // Blue
      const Color(0xFF6C757D), // Grey
      Colors.teal,
      Colors.indigo,
    ];
    int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase();
    if (r == 'manager') return Colors.amber.shade200;
    if (r == 'supervisor') return Colors.grey.shade300;
    if (r == 'operative') return const Color(0xFFFEF3C7); // Warm yellow
    if (r == 'admin') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  Color _getRoleTextColor(String role) {
    final r = role.toLowerCase();
    if (r == 'manager') return Colors.black87;
    if (r == 'supervisor') return Colors.black87;
    if (r == 'operative') return const Color(0xFFB45309); // Dark amber/brown
    if (r == 'admin') return Colors.red.shade800;
    return Colors.black87;
  }

  Widget _buildSummaryCard(bool isDark) {
    final assigned = _controller.assignedCount ?? _controller.totalCount;
    final invited = _controller.invitedCount ?? 0;
    final totalSeats = _controller.totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(IconlyLight.work, color: Color(0xFF0D6EFD), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Euroside",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Job sheets, approvals, scheduling and project operations access.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                child: Text(
                  "$totalSeats seats",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Assigned ",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    Text(
                      "$assigned",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Invited ",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    Text(
                      "$invited",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSegmentedControl(bool isDark) {
    final activeStatus = _controller.statusFilter;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Active Tab
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _controller.setStatusFilter('active'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: activeStatus == 'active'
                      ? const Color(0xFF0D6EFD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: activeStatus == 'active'
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: activeStatus == 'active'
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Pending Tab
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _controller.setStatusFilter('pending'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: activeStatus == 'pending'
                      ? const Color(0xFF0D6EFD)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: activeStatus == 'pending'
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pending",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: activeStatus == 'pending'
                              ? Colors.white
                              : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                        ),
                      ),
                      if ((_controller.invitedCount ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeStatus == 'pending' ? Colors.white24 : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_controller.invitedCount}",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: activeStatus == 'pending' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar(bool isDark) {
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final searchFillColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? AppTheme.darkText : Colors.black87;
    final subtitleColor = isDark ? AppTheme.darkMuted : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Input Field
          TextField(
            controller: _searchFieldController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Search member...",
              hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
              prefixIcon: Icon(IconlyLight.search, color: subtitleColor, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: subtitleColor),
                      onPressed: () {
                        _searchFieldController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              filled: true,
              fillColor: searchFillColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
          ),
          const SizedBox(height: 10),

          // Role Filter + Export + Reset + Invite Button Row
          Row(
            children: [
              // Role Filter Dropdown
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: searchFillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _controller.roleFilter,
                      isExpanded: true,
                      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                      style: TextStyle(fontSize: 13, color: textColor),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text("Role: All")),
                        DropdownMenuItem(value: 'manager', child: Text("Manager")),
                        DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
                        DropdownMenuItem(value: 'operative', child: Text("Operative")),
                        DropdownMenuItem(value: 'admin', child: Text("Admin")),
                        DropdownMenuItem(value: 'custom', child: Text("Custom")),
                      ],
                      onChanged: (val) {
                        if (val != null) _controller.setRoleFilter(val);
                      },
                      icon: Icon(IconlyLight.arrow_down_2, size: 14, color: subtitleColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: "Export members",
                onPressed: _exportMembers,
                icon: Icon(IconlyLight.download, color: subtitleColor, size: 20),
              ),
              IconButton(
                tooltip: "Import members from Excel",
                onPressed: _showImportMembersDialog,
                icon: Icon(IconlyLight.upload, color: subtitleColor, size: 20),
              ),
              IconButton(
                tooltip: "Reset filters",
                onPressed: _resetFilters,
                icon: Icon(Icons.refresh, color: subtitleColor, size: 20),
              ),
              const SizedBox(width: 4),

              // + Invite Action Button
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  onPressed: _showInviteDialog,
                  icon: const Icon(IconlyLight.add_user, size: 16),
                  label: const Text(
                    "+ Invite",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMemberCard(
    AdminMember member, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final initials = member.displayName.isNotEmpty
        ? member.displayName.substring(0, 2).toUpperCase()
        : (member.email.isNotEmpty ? member.email.substring(0, 2).toUpperCase() : "U");
    final avatarColor = _getAvatarColor(member.displayName.isNotEmpty ? member.displayName : member.email);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showMemberDetails(member),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (member.isActive)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName.isNotEmpty ? member.displayName : member.email,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.email,
                            style: TextStyle(color: subtitleColor, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getRoleColor(member.role),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              member.roleDisplayName.isNotEmpty
                                  ? member.roleDisplayName
                                  : member.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getRoleTextColor(member.role),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(IconlyLight.more_circle, color: Colors.grey, size: 20),
                      onSelected: (val) {
                        if (val == 'view') _showMemberDetails(member);
                        if (val == 'edit') _showEditDialog(member);
                        if (val == 'password') _showChangePasswordDialog(member);
                        if (val == 'qualification') _showQualificationsDialog(member);
                        if (val == 'convert') _confirmConvertToGuest(member);
                        if (val == 'delete') _deleteMember(member);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text("View Profile"),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("Update Member"),
                        ),
                        const PopupMenuItem(
                          value: 'password',
                          child: Text("Change Password"),
                        ),
                        const PopupMenuItem(
                          value: 'qualification',
                          child: Text("Add Qualification"),
                        ),
                        const PopupMenuItem(
                          value: 'convert',
                          child: Text("Convert to Guest"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("Delete Member", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TEAM",
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.teamName.isNotEmpty ? member.teamName : "-",
                            style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PHONE",
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.phone.isNotEmpty ? member.phone : "-",
                            style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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

  Widget _buildPendingMemberCard(
    AdminMember member, {
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Email & Actions
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(IconlyLight.message, color: Color(0xFF0D6EFD), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Text(
                              "Sent",
                              style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member.roleDisplayName.isNotEmpty ? member.roleDisplayName : member.role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getRoleTextColor(member.role),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(IconlyLight.more_circle, color: Colors.grey, size: 20),
                  onSelected: (val) {
                    if (val == 'resend') _resendInvite(member);
                    if (val == 'copy') _copyInviteLink(member);
                    if (val == 'revoke') _deleteMember(member);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'resend',
                      child: Row(
                        children: [
                          Icon(IconlyLight.send, size: 16, color: Color(0xFF0D6EFD)),
                          SizedBox(width: 8),
                          Text("Resend Invite"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(IconlyLight.paper, size: 16),
                          SizedBox(width: 8),
                          Text("Copy Email"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'revoke',
                      child: Row(
                        children: [
                          Icon(IconlyLight.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Revoke Invite", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 10),

            // Bottom Info: Team and Sent Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "TEAM: ",
                      style: TextStyle(fontSize: 11, color: subtitleColor, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      member.teamName.isNotEmpty ? member.teamName : "-",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(IconlyLight.time_circle, size: 12, color: subtitleColor),
                    const SizedBox(width: 4),
                    Text(
                      DateHelper.formatToLocal(member.createdAt),
                      style: TextStyle(fontSize: 11, color: subtitleColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? AppTheme.darkText : Colors.black87;
    final subtitleColor = isDark ? AppTheme.darkMuted : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Members"),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F2C4A),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isPendingTab = _controller.statusFilter == 'pending';
          final filteredMembers = _controller.members.where((m) {
            final matchesQuery = _searchQuery.isEmpty ||
                m.displayName.toLowerCase().contains(_searchQuery) ||
                m.email.toLowerCase().contains(_searchQuery) ||
                m.teamName.toLowerCase().contains(_searchQuery);

            if (!matchesQuery) return false;

            if (_controller.roleFilter != 'all') {
              if (m.role.toLowerCase() != _controller.roleFilter.toLowerCase()) {
                return false;
              }
            }

            return true;
          }).toList();

          return Column(
            children: [
              // 1. Organization Summary Seats Card
              _buildSummaryCard(isDark),

              // 2. Active vs Pending Segmented Switcher
              _buildStatusSegmentedControl(isDark),

              // 3. Search & Role Filter Bar
              _buildFilterAndSearchBar(isDark),

              // 4. Members List
              Expanded(
                child: _controller.isLoading && _controller.members.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.errorMessage != null && _controller.members.isEmpty
                        ? Center(
                            child: Text(
                              _controller.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : filteredMembers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isPendingTab ? IconlyLight.send : IconlyLight.user_1,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      isPendingTab
                                          ? "No pending invitations found."
                                          : "No active members found.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    if (isPendingTab) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D6EFD),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: _showInviteDialog,
                                        icon: const Icon(IconlyLight.add_user, size: 16),
                                        label: const Text("Invite Member"),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        onPressed: _resetFilters,
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text("Reset filters"),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                itemCount: filteredMembers.length,
                                itemBuilder: (context, index) {
                                  final member = filteredMembers[index];
                                  if (isPendingTab) {
                                    return _buildPendingMemberCard(
                                      member,
                                      isDark: isDark,
                                      cardColor: cardColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      subtitleColor: subtitleColor,
                                    );
                                  }
                                  return _buildActiveMemberCard(
                                    member,
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
