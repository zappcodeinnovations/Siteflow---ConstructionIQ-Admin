import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'admin_guests_controller.dart';
import '../../../../models/admin_guest_model.dart';

class EditGuestDialog extends StatefulWidget {
  final AdminGuest guest;
  final AdminGuestsController controller;
  
  const EditGuestDialog({super.key, required this.guest, required this.controller});

  @override
  State<EditGuestDialog> createState() => _EditGuestDialogState();
}

class _EditGuestDialogState extends State<EditGuestDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  final _projectIdsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.guest.firstName);
    // Ideally we fetch current project IDs, but leaving blank as per API limitation.
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _projectIdsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    List<int> projectIds = [];
    if (_projectIdsController.text.isNotEmpty) {
      try {
        projectIds = _projectIdsController.text.split(',').map((e) => int.parse(e.trim())).toList();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Project IDs format. Use comma separated numbers.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        return;
      }
    }

    final payload = {
      "first_name": _firstNameController.text.trim(),
      if (projectIds.isNotEmpty) "project_ids": projectIds,
    };

    final result = await widget.controller.updateGuest(widget.guest.id, payload);

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
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Guest",
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
                controller: _firstNameController,
                decoration: _buildInputDecoration("First Name", IconlyLight.profile, isDark),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _projectIdsController,
                decoration: _buildInputDecoration("Project IDs (comma separated)", IconlyLight.folder, isDark),
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
                    : const Text("Update Guest", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
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
