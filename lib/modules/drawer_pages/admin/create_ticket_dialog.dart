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

  InputDecoration _buildInputDecoration({required String hintText, required bool isDark}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500),
      filled: true,
      fillColor: isDark ? const Color(0xFF162A42) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F2C4A) : Colors.white,
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
                  Text(
                    "Create Support Ticket",
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
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Subject", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDecoration(hintText: "Briefly describe the issue", isDark: isDark),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 450;
                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                  decoration: _buildInputDecoration(hintText: "Select Category", isDark: isDark),
                                  items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) => setState(() => _selectedCategory = val!),
                                ),
                                const SizedBox(height: 16),
                                Text("Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedPriority,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                  decoration: _buildInputDecoration(hintText: "Select Priority", isDark: isDark),
                                  items: _priorities.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) => setState(() => _selectedPriority = val!),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                      decoration: _buildInputDecoration(hintText: "Select Category", isDark: isDark),
                                      items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) => setState(() => _selectedCategory = val!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _selectedPriority,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                      decoration: _buildInputDecoration(hintText: "Select Priority", isDark: isDark),
                                      items: _priorities.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) => setState(() => _selectedPriority = val!),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      Text("Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _buildInputDecoration(hintText: "Add the page, user, project, job number, and what you expected to happen.", isDark: isDark),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      Text("Attachment or screenshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162A42) : Colors.transparent,
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F2C4A) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                              ),
                              child: Text("Choose File", style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                            ),
                            const SizedBox(width: 12),
                            Text("No file chosen", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
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
