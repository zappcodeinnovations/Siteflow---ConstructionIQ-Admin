import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/admin_member_model.dart';
import 'admin_members_controller.dart';
import 'package:intl/intl.dart';

class MemberDetailsDialog extends StatefulWidget {
  final int memberId;
  final AdminMembersController controller;

  const MemberDetailsDialog({
    super.key,
    required this.memberId,
    required this.controller,
  });

  @override
  State<MemberDetailsDialog> createState() => _MemberDetailsDialogState();
}

class _MemberDetailsDialogState extends State<MemberDetailsDialog> {
  AdminMember? member;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final fetchedMember = await widget.controller.fetchMemberDetails(widget.memberId);
    if (mounted) {
      setState(() {
        member = fetchedMember;
        isLoading = false;
      });
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [const Color(0xFF0F2C4A), const Color(0xFF0D6EFD), const Color(0xFF6C757D), Colors.teal, Colors.indigo];
    int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  Color _getRoleColor(String role) {
    if (role.toLowerCase() == 'manager') return Colors.amber.shade100;
    if (role.toLowerCase() == 'supervisor') return Colors.purple.shade100;
    if (role.toLowerCase() == 'operative') return Colors.blue.shade100;
    if (role.toLowerCase() == 'admin') return Colors.red.shade100;
    return Colors.grey.shade200;
  }

  Color _getRoleTextColor(String role) {
    if (role.toLowerCase() == 'manager') return Colors.amber.shade900;
    if (role.toLowerCase() == 'supervisor') return Colors.purple.shade900;
    if (role.toLowerCase() == 'operative') return Colors.blue.shade900;
    if (role.toLowerCase() == 'admin') return Colors.red.shade900;
    return Colors.black87;
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
            : member == null
                ? SizedBox(
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(IconlyLight.danger, color: Colors.red, size: 56),
                        const SizedBox(height: 16),
                        const Text("Oops!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        const Text("Failed to load member details.", style: TextStyle(color: Colors.grey)),
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
                        // Header with Avatar
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
                                backgroundColor: _getAvatarColor(member!.displayName),
                                child: Text(
                                  member!.displayName.isNotEmpty ? member!.displayName.substring(0, 2).toUpperCase() : "U",
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Name and Role
                        Text(
                          member!.displayName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getRoleColor(member!.role),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                member!.roleDisplayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleTextColor(member!.role),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: member!.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: member!.isActive ? Colors.green.shade200 : Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: member!.isActive ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    member!.isActive ? "Active" : "Inactive",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: member!.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info Sections
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("Contact Information"),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.message, "Email", member!.email),
                                _buildInfoRow(IconlyLight.call, "Phone", member!.phone.isNotEmpty ? member!.phone : "N/A"),
                              ]),
                              
                              const SizedBox(height: 20),
                              
                              _buildSectionTitle("Company Details"),
                              _buildInfoCard([
                                _buildInfoRow(IconlyLight.document, "Employee ID", member!.employeeId.isNotEmpty ? member!.employeeId : "N/A"),
                                _buildInfoRow(IconlyLight.user_1, "Username", member!.username),
                                _buildInfoRow(IconlyLight.user_1, "Team", member!.teamName),
                                if (member!.createdAt.isNotEmpty)
                                  _buildInfoRow(IconlyLight.calendar, "Joined", _formatDate(member!.createdAt)),
                              ]),
                              
                              if (member!.onetraceProEnabled) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.purple.shade50, Colors.purple.shade100],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.purple.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(IconlyLight.category, color: Colors.purple.shade700, size: 20),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("OneTrace Pro Enabled", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade900)),
                                            Text("This member has pro features.", style: TextStyle(fontSize: 12, color: Colors.purple.shade700)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
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
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
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
