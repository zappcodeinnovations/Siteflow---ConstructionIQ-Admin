import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  PlatformFile? _selectedFile;

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

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick file: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedFile = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  bool _isImageFile(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length <= 1) return false;
    final ext = parts.last;
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic'].contains(ext);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    String? attachmentBase64;
    String? attachmentName;
    if (_selectedFile != null) {
      attachmentName = _selectedFile!.name;
      if (_selectedFile!.bytes != null) {
        attachmentBase64 = base64Encode(_selectedFile!.bytes!);
      }
    }

    final result = await widget.controller.submitTicket(
      subject: _subjectController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      body: _messageController.text.trim(),
      attachmentBase64: attachmentBase64,
      attachmentName: attachmentName,
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
                                  initialValue: _selectedCategory,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                  decoration: _buildInputDecoration(hintText: "Select Category", isDark: isDark),
                                  items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text("Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedPriority,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                  decoration: _buildInputDecoration(hintText: "Select Priority", isDark: isDark),
                                  items: _priorities.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedPriority = val);
                                  },
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
                                      initialValue: _selectedCategory,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                      decoration: _buildInputDecoration(hintText: "Select Category", isDark: isDark),
                                      items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedCategory = val);
                                      },
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
                                      initialValue: _selectedPriority,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                      icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                      decoration: _buildInputDecoration(hintText: "Select Priority", isDark: isDark),
                                      items: _priorities.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedPriority = val);
                                      },
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
                      
                      // Attachment picker or preview container with delete action
                      if (_selectedFile == null)
                        InkWell(
                          onTap: _pickAttachment,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF162A42) : Colors.transparent,
                              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
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
                                  child: Text("Choose File", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text("No file chosen", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF162A42) : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isDark ? const Color(0xFF0D6EFD).withValues(alpha: 0.5) : const Color(0xFF93C5FD),
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // File thumbnail / icon
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _selectedFile!.bytes != null && _isImageFile(_selectedFile!.name)
                                    ? Image.memory(
                                        _selectedFile!.bytes!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(IconlyLight.image, color: Color(0xFF0D6EFD), size: 20),
                                      )
                                    : Icon(
                                        _isImageFile(_selectedFile!.name) ? IconlyLight.image : IconlyLight.document,
                                        color: const Color(0xFF0D6EFD),
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // File Name and formatted size
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedFile!.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatFileSize(_selectedFile!.size),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Dedicated Delete / Trash button
                              IconButton(
                                onPressed: _removeAttachment,
                                tooltip: "Remove attachment",
                                icon: const Icon(
                                  IconlyLight.delete,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50,
                                  padding: const EdgeInsets.all(8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
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
