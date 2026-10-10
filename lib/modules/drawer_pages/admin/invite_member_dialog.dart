import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_team_model.dart';
import 'admin_members_controller.dart';

class InviteMemberDialog extends StatefulWidget {
  final AdminMembersController controller;

  const InviteMemberDialog({super.key, required this.controller});

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _mobileController = TextEditingController();

  int? _selectedTeamId;
  String _selectedRole = 'admin';

  List<AdminTeam> _teams = [];
  bool _isLoadingTeams = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _employeeCodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoadingTeams = true);
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map ? decoded['data'] : null) as List?;
        if (list != null && mounted) {
          setState(() {
            _teams = list
                .whereType<Map>()
                .map((e) => AdminTeam.fromJson(e.cast<String, dynamic>()))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to load teams: $e");
    } finally {
      if (mounted) setState(() => _isLoadingTeams = false);
    }
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Full access to everything on all devices.';
      case 'manager':
        return 'Access to manage projects, assign tasks, and view reports.';
      case 'supervisor':
        return 'Access to supervise team operations and daily job sheets.';
      case 'operative':
        return 'Access to view assigned tasks and submit job sheets.';
      default:
        return 'Standard member access.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final payload = <String, dynamic>{
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "employee_code": _employeeCodeController.text.trim(),
      "employee_id": _employeeCodeController.text.trim(),
      "mobile": _mobileController.text.trim(),
      "phone": _mobileController.text.trim(),
      "role": _selectedRole,
    };

    if (_selectedTeamId != null) {
      payload["team_id"] = _selectedTeamId;
    }

    final result = await widget.controller.inviteMember(payload);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRequired)
            const Text(
              "* ",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFF0D6EFD),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: Color(0xFF0D6EFD),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Invite Member",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white24 : Colors.grey.shade200),
                const SizedBox(height: 12),

                // Section Title
                Text(
                  "Enter member details",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                  ),
                ),
                const SizedBox(height: 16),

                // 1. First Name *
                _buildFieldLabel("First Name", isRequired: true, isDark: isDark),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration(hintText: "First Name", isDark: isDark),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'First Name is required' : null,
                ),
                const SizedBox(height: 14),

                // 2. Last Name *
                _buildFieldLabel("Last Name", isRequired: true, isDark: isDark),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration(hintText: "Last Name", isDark: isDark),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Last Name is required' : null,
                ),
                const SizedBox(height: 14),

                // 3. Email *
                _buildFieldLabel("Email", isRequired: true, isDark: isDark),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(hintText: "Email", isDark: isDark),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 4. Employee Code *
                _buildFieldLabel("Employee Code", isRequired: true, isDark: isDark),
                TextFormField(
                  controller: _employeeCodeController,
                  decoration: _inputDecoration(hintText: "Employee Code", isDark: isDark),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Employee Code is required' : null,
                ),
                const SizedBox(height: 14),

                // 5. Mobile Number *
                _buildFieldLabel("Mobile Number", isRequired: true, isDark: isDark),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(hintText: "10 digit mobile number", isDark: isDark),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Mobile Number is required' : null,
                ),
                const SizedBox(height: 14),

                // 6. Team
                _buildFieldLabel("Team", isRequired: false, isDark: isDark),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedTeamId,
                  isExpanded: true,
                  decoration: _inputDecoration(hintText: "Select Team", isDark: isDark),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        _isLoadingTeams ? "Loading teams..." : "Select Team",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    ..._teams.map((team) => DropdownMenuItem<int?>(
                          value: team.id,
                          child: Text(
                            team.displayName.isNotEmpty ? team.displayName : team.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedTeamId = val);
                  },
                ),
                const SizedBox(height: 14),

                // 7. Role *
                _buildFieldLabel("Role", isRequired: true, isDark: isDark),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  isExpanded: true,
                  decoration: _inputDecoration(hintText: "Role", isDark: isDark),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text("Admin")),
                    DropdownMenuItem(value: 'manager', child: Text("Manager")),
                    DropdownMenuItem(value: 'supervisor', child: Text("Supervisor")),
                    DropdownMenuItem(value: 'operative', child: Text("Operative")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Role permission helper description
                Text(
                  _getRoleDescription(_selectedRole),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),

                // Invitation email dispatch notice
                Text(
                  "A Euroside invite email will be sent with a temporary password and a secure setup link so the user can set their own password.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),

                // Modal Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Invite",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
