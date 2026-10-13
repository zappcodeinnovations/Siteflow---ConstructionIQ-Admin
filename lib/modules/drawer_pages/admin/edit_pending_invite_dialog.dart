import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_member_model.dart';
import 'admin_members_controller.dart';

/// Edits the invite record itself (rather than a Member account).  Pending
/// invitations use MemberInvite ids, so the active-member edit dialog cannot
/// safely be reused here.
class EditPendingInviteDialog extends StatefulWidget {
  final AdminMembersController controller;
  final AdminMember invite;

  const EditPendingInviteDialog({
    super.key,
    required this.controller,
    required this.invite,
  });

  @override
  State<EditPendingInviteDialog> createState() =>
      _EditPendingInviteDialogState();
}

class _EditPendingInviteDialogState extends State<EditPendingInviteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.invite.firstName);
  late final _lastName = TextEditingController(text: widget.invite.lastName);
  late final _email = TextEditingController(text: widget.invite.email);
  late final _employeeId = TextEditingController(
    text: widget.invite.employeeId,
  );
  late final _phone = TextEditingController(text: widget.invite.phone);
  late String _role = widget.invite.role.isEmpty
      ? 'operative'
      : widget.invite.role;
  int? _teamId;
  List<Map<String, dynamic>> _teams = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _teamId = widget.invite.team;
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/admin/teams/',
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items = decoded['data'] as List? ?? const [];
      if (mounted)
        setState(
          () => _teams = items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
    } catch (_) {
      // The existing assigned team remains selectable even when offline.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _employeeId.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await widget.controller
        .updatePendingInvite(widget.invite.id, {
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'email': _email.text.trim(),
          'employee_id': _employeeId.text.trim(),
          'phone': _phone.text.trim(),
          'role': _role,
          'team_id': _teamId,
        });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Navigator.pop(context, result['message']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Unable to update invite.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Colors.white : const Color(0xFF172033);
    return AlertDialog(
      title: const Text('Edit Invite'),
      content: SizedBox(
        width: 460,
        child: _loading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field(
                        _firstName,
                        'First name',
                        required: true,
                        textColor: textColor,
                      ),
                      _field(_lastName, 'Last name', textColor: textColor),
                      _field(
                        _email,
                        'Email',
                        required: true,
                        email: true,
                        textColor: textColor,
                      ),
                      _field(
                        _employeeId,
                        'Employee ID',
                        required: true,
                        textColor: textColor,
                      ),
                      _field(_phone, 'Mobile number', textColor: textColor),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value:
                            const [
                              'admin',
                              'manager',
                              'supervisor',
                              'operative',
                              'custom',
                            ].contains(_role)
                            ? _role
                            : 'operative',
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Manager'),
                          ),
                          DropdownMenuItem(
                            value: 'supervisor',
                            child: Text('Supervisor'),
                          ),
                          DropdownMenuItem(
                            value: 'operative',
                            child: Text('Operative'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('Custom role'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _role = value ?? 'operative'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _teams.any((team) => team['id'] == _teamId)
                            ? _teamId
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Team',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No team'),
                          ),
                          ..._teams.map(
                            (team) => DropdownMenuItem<int?>(
                              value: team['id'] as int?,
                              child: Text(
                                team['name']?.toString() ?? 'Unnamed team',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _teamId = value),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Invite'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    required Color textColor,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      style: TextStyle(color: textColor),
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final input = value?.trim() ?? '';
        if (required && input.isEmpty) return '$label is required';
        if (email && input.isNotEmpty && !input.contains('@'))
          return 'Enter a valid email address';
        return null;
      },
    ),
  );
}
