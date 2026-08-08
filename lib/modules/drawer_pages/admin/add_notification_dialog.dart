import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'admin_notifications_controller.dart';

class AddNotificationDialog extends StatefulWidget {
  final AdminNotificationsController controller;
  const AddNotificationDialog({super.key, required this.controller});

  @override
  State<AddNotificationDialog> createState() => _AddNotificationDialogState();
}

class _AddNotificationDialogState extends State<AddNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _headlineController = TextEditingController();
  final _textController = TextEditingController();
  final _operatorIdsController = TextEditingController();
  
  String _audience = "all";
  bool _isActive = true;
  bool _sendPush = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _headlineController.dispose();
    _textController.dispose();
    _operatorIdsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    List<int> operatorIds = [];
    if (_audience == "selected_operators" && _operatorIdsController.text.isNotEmpty) {
      operatorIds = _operatorIdsController.text
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    }

    final payload = {
      "headline": _headlineController.text.trim(),
      "notification_text": _textController.text.trim(),
      "audience": _audience,
      if (_audience == "selected_operators") "operator_ids": operatorIds,
      "is_active": _isActive,
      "send_push": _sendPush,
      "attachment": null,
    };

    final result = await widget.controller.createNotification(payload);

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
                    const Text("Create Notification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                    IconButton(
                      icon: const Icon(IconlyLight.close_square, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _headlineController,
                  decoration: _buildInputDecoration("Headline", IconlyLight.document),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: _buildInputDecoration("Notification Text", IconlyLight.message),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _audience,
                  decoration: _buildInputDecoration("Audience", IconlyLight.user_1),
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All Operators")),
                    DropdownMenuItem(value: "selected_operators", child: Text("Selected Operators")),
                  ],
                  onChanged: (val) => setState(() => _audience = val ?? "all"),
                ),
                if (_audience == "selected_operators") ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _operatorIdsController,
                    decoration: _buildInputDecoration("Operator IDs (comma separated)", IconlyLight.category),
                    validator: (val) => val == null || val.isEmpty ? "Required for selected operators" : null,
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Is Active", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                  value: _isActive,
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                SwitchListTile(
                  title: const Text("Send Push Notification", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                  value: _sendPush,
                  activeColor: Colors.blue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _sendPush = val),
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
                      : const Text("Send Notification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
