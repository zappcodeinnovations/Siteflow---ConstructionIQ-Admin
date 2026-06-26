import 'package:flutter/material.dart';
import 'admin_announcements_controller.dart';

class AddAnnouncementDialog extends StatefulWidget {
  final AdminAnnouncementsController controller;

  const AddAnnouncementDialog({super.key, required this.controller});

  @override
  State<AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<AddAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();

  final _headlineController = TextEditingController();
  final _textController = TextEditingController();
  final _operatorIdsController = TextEditingController();

  String _selectedAudience = 'all_operators';
  bool _isActive = true;
  bool _sendPush = true;

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    List<int> operatorIds = [];
    if (_selectedAudience == 'selected_operators') {
      final parts = _operatorIdsController.text.split(',');
      for (var p in parts) {
        final id = int.tryParse(p.trim());
        if (id != null) operatorIds.add(id);
      }
    }

    final payload = {
      "headline": _headlineController.text.trim(),
      "notification_text": _textController.text.trim(),
      "audience": _selectedAudience,
      "operator_ids": operatorIds,
      "is_active": _isActive,
      "send_push": _sendPush,
      "attachment": null,
    };

    final result = await widget.controller.createNotification(payload);

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

  @override
  Widget build(BuildContext context) {
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
                    const Text("Add Announcement", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _headlineController,
                  decoration: const InputDecoration(labelText: "Headline", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(labelText: "Notification Text", border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Audience", border: OutlineInputBorder()),
                  value: _selectedAudience,
                  items: const [
                    DropdownMenuItem(value: 'all_operators', child: Text("All Operators")),
                    DropdownMenuItem(value: 'selected_operators', child: Text("Selected Operators")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAudience = val);
                  },
                ),
                const SizedBox(height: 16),

                if (_selectedAudience == 'selected_operators') ...[
                  TextFormField(
                    controller: _operatorIdsController,
                    decoration: const InputDecoration(
                      labelText: "Operator IDs (Comma separated)", 
                      border: OutlineInputBorder(),
                      hintText: "e.g. 1, 5, 8",
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        title: const Text("Is Active", style: TextStyle(fontSize: 14)),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text("Send Push", style: TextStyle(fontSize: 14)),
                        value: _sendPush,
                        onChanged: (val) => setState(() => _sendPush = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
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
                        : const Text("Add Announcement", style: TextStyle(color: Colors.white, fontSize: 16)),
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
