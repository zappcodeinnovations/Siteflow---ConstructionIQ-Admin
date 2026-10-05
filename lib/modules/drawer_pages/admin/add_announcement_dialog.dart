import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Text(
                      "Add Announcement",
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
                TextFormField(
                  controller: _titleController,
                  decoration: _buildInputDecoration("Announcement Title", IconlyLight.document, isDark),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _projectIdController,
                  decoration: _buildInputDecoration("Project ID (optional)", IconlyLight.folder, isDark),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: _buildInputDecoration("Message", IconlyLight.message, isDark),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text("Is Active", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text("Make this announcement visible immediately", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
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

  InputDecoration _buildInputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
    );
  }
}
