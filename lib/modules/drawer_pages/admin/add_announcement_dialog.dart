import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/project_model.dart';
import 'admin_announcements_controller.dart';

class AddAnnouncementDialog extends StatefulWidget {
  final AdminAnnouncementsController controller;
  const AddAnnouncementDialog({super.key, required this.controller});

  @override
  State<AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<AddAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  int? _selectedProjectId;
  bool _isActive = true;
  bool _isLoadingProjects = false;
  bool _isSubmitting = false;
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
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
      debugPrint("Error fetching projects for announcement: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final wordCount = _countWords(_messageController.text);
    if (wordCount > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Message exceeds the 250 words limit."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      "title": _titleController.text.trim(),
      "message": _messageController.text.trim(),
      "is_active": _isActive,
      if (_selectedProjectId != null) "project_id": _selectedProjectId,
    };

    final result = await widget.controller.createAnnouncement(payload);

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

    final wordCount = _countWords(_messageController.text);

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
            // Modal Header: Title + Dismiss Cross (x)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Announcement",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
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
                      // Guidance note
                      Text(
                        "Select one project, or choose all projects.",
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 1. * Project
                      _buildFieldLabel("Project", isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      _isLoadingProjects
                          ? Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              alignment: Alignment.centerLeft,
                              child: const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : DropdownButtonFormField<int?>(
                              value: _selectedProjectId,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                hintText: "Select project",
                                isDark: isDark,
                                inputBg: inputBg,
                                borderColor: borderColor,
                              ),
                              dropdownColor: bgColor,
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    "All Projects",
                                    style: TextStyle(color: textColor, fontSize: 14),
                                  ),
                                ),
                                ..._projects.map((p) {
                                  return DropdownMenuItem<int?>(
                                    value: p.id,
                                    child: Text(
                                      "${p.name} (${p.code})",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: textColor, fontSize: 14),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) => setState(() => _selectedProjectId = val),
                            ),
                      const SizedBox(height: 16),

                      // 2. * Title
                      _buildFieldLabel("Title", isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: "Enter announcement title",
                          isDark: isDark,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? "Title is required" : null,
                      ),
                      const SizedBox(height: 16),

                      // 3. * Message
                      _buildFieldLabel("Message", isRequired: true, textColor: textColor),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: _inputDecoration(
                          hintText: "Enter announcement message",
                          isDark: isDark,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? "Message is required" : null,
                      ),
                      const SizedBox(height: 6),

                      // Word count indicator
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "$wordCount/250 words",
                          style: TextStyle(
                            fontSize: 12,
                            color: wordCount > 250 ? Colors.red : secondaryTextColor,
                            fontWeight: wordCount > 250 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Active announcement checkbox
                      InkWell(
                        onTap: () => setState(() => _isActive = !_isActive),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _isActive,
                                activeColor: const Color(0xFF0D6EFD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) => setState(() => _isActive = val ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Active announcement",
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),

            // Modal Actions Footer: Cancel & Save Announcement
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
                            "Save Announcement",
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
        if (isRequired) ...[
          const Text(
            "* ",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
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
