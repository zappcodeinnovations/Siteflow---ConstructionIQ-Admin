import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'admin_support_controller.dart';

class CreateTicketDialog extends StatefulWidget {
  final AdminSupportController controller;

  const CreateTicketDialog({super.key, required this.controller});

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'login_access';
  String _selectedPriority = 'normal';

  final List<Map<String, String>> _categories = [
    {'value': 'login_access', 'label': 'Login & access'},
    {'value': 'attendance_timesheets', 'label': 'Attendance & timesheets'},
    {'value': 'projects', 'label': 'Projects & forms'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'high', 'label': 'High'},
    {'value': 'urgent', 'label': 'Urgent'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await widget.controller.submitTicket(
      subject: _subjectController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      body: _messageController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
      );
      if (result['success']) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
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
                  const Text("Create Support Ticket", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                  IconButton(
                    icon: const Icon(IconlyLight.close_square, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Subject", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Briefly describe the issue", contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                  items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
                                  onChanged: (val) => setState(() => _selectedCategory = val!),
                                ),
                              ],
                            )
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedPriority,
                                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                  items: _priorities.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!))).toList(),
                                  onChanged: (val) => setState(() => _selectedPriority = val!),
                                ),
                              ],
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text("Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Add the page, user, project, job number, and what you expected to happen.", contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text("Attachment or screenshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                              child: const Text("Choose File", style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            const Text("No file chosen", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: widget.controller,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: widget.controller.isSubmitting ? null : _submitForm,
                      icon: widget.controller.isSubmitting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(IconlyLight.send, color: Colors.white, size: 18),
                      label: const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
