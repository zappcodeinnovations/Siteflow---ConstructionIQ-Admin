import 'package:flutter/material.dart';
import 'admin_members_controller.dart';
import '../../../../models/admin_member_model.dart';
import 'package:iconly/iconly.dart';

class EditMemberDialog extends StatefulWidget {
  final AdminMembersController controller;
  final AdminMember member;

  const EditMemberDialog({super.key, required this.controller, required this.member});

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _firstNameController =
      TextEditingController(text: widget.member.firstName);
  late final _lastNameController =
      TextEditingController(text: widget.member.lastName);
  late final _emailController = TextEditingController(text: widget.member.email);
  late final _employeeIdController =
      TextEditingController(text: widget.member.employeeId);
  late final _phoneController = TextEditingController(text: widget.member.phone);
  late final _teamIdController =
      TextEditingController(text: widget.member.team?.toString() ?? '');

  late String _selectedRole = widget.member.role;
  late bool _onetraceProEnabled = widget.member.onetraceProEnabled;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "employee_id": _employeeIdController.text.trim(),
      "phone": _phoneController.text.trim(),
      "role": _selectedRole,
      "onetrace_pro_enabled": _onetraceProEnabled,
    };
    final teamIdText = _teamIdController.text.trim();
    payload["team_id"] = teamIdText.isEmpty ? '' : (int.tryParse(teamIdText) ?? teamIdText);

    final result = await widget.controller.updateMember(widget.member.id, payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Member",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(IconlyLight.close_square, color: isDark ? Colors.white70 : Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _employeeIdController,
                        decoration: const InputDecoration(labelText: "Employee ID", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: "Mobile", border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Role", border: OutlineInputBorder()),
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  initialValue: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'operative', child: Text("Operative")),
                    DropdownMenuItem(value: 'manager', child: Text("Manager")),
                    DropdownMenuItem(value: 'admin', child: Text("Admin")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _teamIdController,
                  decoration: const InputDecoration(labelText: "Team ID", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: Text(
                    "OneTrace Pro Enabled",
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  value: _onetraceProEnabled,
                  onChanged: (val) => setState(() => _onetraceProEnabled = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
