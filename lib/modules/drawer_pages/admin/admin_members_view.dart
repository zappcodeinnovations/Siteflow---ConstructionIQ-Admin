import 'package:flutter/material.dart';
import 'admin_members_controller.dart';
import 'invite_member_dialog.dart';
import 'member_details_dialog.dart';
import '../../../../models/admin_member_model.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:iconly/iconly.dart';

class AdminMembersView extends StatefulWidget {
  const AdminMembersView({super.key});

  @override
  State<AdminMembersView> createState() => _AdminMembersViewState();
}

class _AdminMembersViewState extends State<AdminMembersView> {
  final AdminMembersController _controller = AdminMembersController();
  String _searchQuery = "";
  int _currentPage = 1;
  final int _pageSize = 20; // Default page size from response

  @override
  void initState() {
    super.initState();
    _controller.fetchMembers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteMemberDialog(controller: _controller),
    );
  }

  void _deleteMember(AdminMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Member"),
        content: Text("Are you sure you want to remove ${member.email}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final result = await _controller.deleteMember(member.id);
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
    if (role.toLowerCase() == 'manager') return Colors.amber.shade200;
    if (role.toLowerCase() == 'supervisor') return Colors.grey.shade300;
    if (role.toLowerCase() == 'operative') return Colors.blue.shade100;
    if (role.toLowerCase() == 'admin') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  Color _getRoleTextColor(String role) {
    if (role.toLowerCase() == 'manager') return Colors.black87;
    if (role.toLowerCase() == 'supervisor') return Colors.black87;
    if (role.toLowerCase() == 'operative') return Colors.blue.shade800;
    if (role.toLowerCase() == 'admin') return Colors.red.shade800;
    return Colors.black87;
  }

  Widget _buildMemberCard(
    AdminMember member, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final initials = member.displayName.isNotEmpty
        ? member.displayName.substring(0, 2).toUpperCase()
        : "U";
    final avatarColor = _getAvatarColor(member.displayName);

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
                return MemberDetailsDialog(
                  memberId: member.id,
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
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (member.isActive)
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
                            member.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.email,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(member.role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              member.roleDisplayName.toUpperCase(),
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
                      icon: const Icon(
                        IconlyLight.more_circle,
                        color: Colors.grey,
                      ),
                      onSelected: (val) {
                        if (val == 'delete') _deleteMember(member);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("Edit Profile"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            "Remove Member",
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
                          "EMPLOYEE ID",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.employeeId.isNotEmpty
                              ? member.employeeId
                              : "N/A",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TEAM",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.teamName.isNotEmpty ? member.teamName : "N/A",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PHONE",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.phone.isNotEmpty ? member.phone : "N/A",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // if (member.onetraceProEnabled)
              //   Padding(
              //     padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              //     child: Container(
              //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //       decoration: BoxDecoration(
              //         color: Colors.purple.shade50,
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Row(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           Icon(IconlyLight.category, color: Colors.purple.shade700, size: 14),
              //           const SizedBox(width: 4),
              //           Text(
              //             "OneTrace Pro",
              //             style: TextStyle(
              //               fontSize: 12,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.purple.shade700,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
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
          final filteredMembers = _controller.members
              .where(
                (m) =>
                    m.displayName.toLowerCase().contains(_searchQuery) ||
                    m.email.toLowerCase().contains(_searchQuery),
              )
              .toList();

          final totalMembers =
              _controller.members.length; // Uses actual fetched count

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
                                "Members\nDirectory",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: headerTitle,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$totalMembers Members Total",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _showInviteDialog,
                          icon: const Icon(
                            IconlyLight.add_user,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            "Invite Member",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
                        hintText: "Search members, roles, or teams...",
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

              // Members List
              Expanded(
                child: _controller.isLoading && _controller.members.isEmpty
                    ? const ShimmerLoadingList()
                    : _controller.errorMessage != null &&
                          _controller.members.isEmpty
                    ? Center(
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          return _buildMemberCard(
                            filteredMembers[index],
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          );
                        },
                      ),
              ),

              // Pagination removed as requested
            ],
          );
        },
      ),
    );
  }
}
