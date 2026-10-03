import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
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
  final _projectIdController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _projectIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    int? projectId;
    if (_projectIdController.text.isNotEmpty) {
      projectId = int.tryParse(_projectIdController.text.trim());
    }

    final payload = {
      "title": _titleController.text.trim(),
      "message": _messageController.text.trim(),
      "is_active": _isActive,
      if (projectId != null) "project_id": projectId,
    };

    final result = await widget.controller.createAnnouncement(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
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
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final inputBg = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
      ),
      child: Container(
        width: 450,
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
                    Text("Add Announcement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                    IconButton(
                      icon: Icon(IconlyLight.close_square, color: textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: borderColor),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration("Announcement Title", IconlyLight.document, inputBg, borderColor, textSecondary),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _projectIdController,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration("Project ID (optional)", IconlyLight.folder, inputBg, borderColor, textSecondary),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: _buildInputDecoration("Message", IconlyLight.message, inputBg, borderColor, textSecondary),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text("Is Active", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  subtitle: Text("Make this announcement visible immediately", style: TextStyle(color: textSecondary, fontSize: 12)),
                  value: _isActive,
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Create Announcement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, Color inputBg, Color borderColor, Color textSecondary) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textSecondary),
      prefixIcon: Icon(icon, color: textSecondary),
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
    );
  }
}
