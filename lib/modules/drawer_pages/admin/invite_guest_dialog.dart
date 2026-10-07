import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/project_model.dart';
import 'admin_guests_controller.dart';

class InviteGuestDialog extends StatefulWidget {
  final AdminGuestsController controller;
  const InviteGuestDialog({super.key, required this.controller});

  @override
  State<InviteGuestDialog> createState() => _InviteGuestDialogState();
}

class _InviteGuestDialogState extends State<InviteGuestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final Set<int> _selectedProjectIds = {};
  List<Project> _projects = [];
  bool _isLoadingProjects = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projects);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        setState(() {
          _projects = list.map((json) => Project.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching projects for invite guest: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one assigned project."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      "email": _emailController.text.trim(),
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "project_ids": _selectedProjectIds.toList(),
    };

    final result = await widget.controller.inviteGuest(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Action completed.'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF2C3E50) : Colors.grey.shade300;
    final inputBg = isDark ? const Color(0xFF152232) : Colors.grey.shade50;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header: Icon + Title + Dismiss Cross (x)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        IconlyLight.add_user,
                        size: 20,
                        color: textColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Invite Guest",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: textColor.withValues(alpha: 0.7),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),

            // Scrollable Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Helper text
                      Text(
                        "Guests receive a secure setup link, username and temporary password.",
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 1. Email *
                      _buildFieldLabel("Email", isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: "Enter email address",
                          isDark: isDark,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Email is required";
                          if (!val.contains('@') || !val.contains('.')) return "Invalid email address";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. First Name
                      _buildFieldLabel("First Name", isRequired: false, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _firstNameController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: "First Name",
                          isDark: isDark,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Last Name *
                      _buildFieldLabel("Last Name", isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _lastNameController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: "Last Name",
                          isDark: isDark,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? "Last name is required" : null,
                      ),
                      const SizedBox(height: 16),

                      // 4. Phone
                      _buildFieldLabel("Phone", isRequired: false, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: "10 digit phone number",
                          isDark: isDark,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Assigned Projects *
                      _buildFieldLabel("Assigned Projects", isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedProjectIds.isEmpty && _isSubmitting
                                ? Colors.red
                                : borderColor,
                          ),
                        ),
                        child: _isLoadingProjects
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : _projects.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        "No projects available",
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: _projects.length,
                                    separatorBuilder: (_, __) => Divider(
                                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                                      height: 1,
                                    ),
                                    itemBuilder: (ctx, i) {
                                      final project = _projects[i];
                                      final isSelected = _selectedProjectIds.contains(project.id);
                                      final codeText = project.code.isNotEmpty ? " (${project.code})" : "";
                                      final displayText = "${project.id} - ${project.name}$codeText";

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedProjectIds.remove(project.id);
                                            } else {
                                              _selectedProjectIds.add(project.id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: Checkbox(
                                                  value: isSelected,
                                                  activeColor: const Color(0xFF0D6EFD),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      if (val == true) {
                                                        _selectedProjectIds.add(project.id);
                                                      } else {
                                                        _selectedProjectIds.remove(project.id);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  displayText,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isSelected ? textColor : secondaryTextColor,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      if (_selectedProjectIds.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          "${_selectedProjectIds.length} project(s) selected",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0D6EFD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),

            // Modal Actions Footer: Cancel & Invite
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Invite",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired, required Color textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          const Text(
            " *",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required Color inputBg,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white38 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
      ),
    );
  }
}
