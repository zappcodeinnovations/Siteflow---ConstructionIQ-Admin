import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_date_picker_dialog.dart';
import '../../../models/project_issue_models.dart';
import '../../../models/admin_member_model.dart';
import '../../drawer_pages/admin/admin_members_controller.dart';
import '../project_issues_controller.dart';

class SnagsTab extends StatefulWidget {
  final int projectId;
  const SnagsTab({super.key, required this.projectId});

  @override
  State<SnagsTab> createState() => _SnagsTabState();
}

class _SnagsTabState extends State<SnagsTab> {
  late final ProjectIssuesController _controller = ProjectIssuesController(widget.projectId);
  String _selectedStatus = 'All statuses';

  final List<String> _statusOptions = [
    'All statuses',
    'Open',
    'Assigned',
    'Rectification',
    'Ready for Inspection',
    'Verified',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();
    _controller.fetchSnags();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showRaiseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RaiseSnagSheet(controller: _controller),
    );
  }

  void _showSnagDetails(SnagModel snag) {
    showDialog(
      context: context,
      builder: (ctx) => _SnagDetailsDialog(
        snag: snag,
        controller: _controller,
        onDelete: () => _confirmDeleteSnag(snag),
      ),
    );
  }

  Future<void> _confirmDeleteSnag(SnagModel snag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Delete Snag", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete snag \"${snag.title}\" (${snag.referenceNo.isNotEmpty ? snag.referenceNo : 'DEF-${snag.id}'})? This action cannot be undone.",
            style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final result = await _controller.deleteSnag(snag.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Snag deleted.'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('verified') || s == 'resolved' || s == 'completed') {
      return const Color(0xFF10B981);
    } else if (s.contains('assigned')) {
      return const Color(0xFF0F2C4A);
    } else if (s.contains('rectification') || s.contains('in progress')) {
      return const Color(0xFF0D6EFD);
    } else if (s.contains('ready') || s.contains('inspection')) {
      return const Color(0xFF8B5CF6);
    } else if (s == 'closed') {
      return Colors.grey.shade600;
    } else {
      return const Color(0xFFF59E0B);
    }
  }

  Color _statusBg(String status, bool isDark) {
    final color = _statusColor(status);
    if (status.toLowerCase().contains('assigned')) {
      return isDark ? const Color(0xFF1F2E40) : const Color(0xFFE2E8F0);
    }
    return isDark ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.12);
  }

  List<SnagModel> _getFilteredSnags() {
    if (_selectedStatus == 'All statuses') {
      return _controller.snags;
    }
    final target = _selectedStatus.toLowerCase().trim();
    return _controller.snags.where((snag) {
      final s = snag.status.toLowerCase().trim();
      final sl = snag.statusLabel.toLowerCase().trim();
      if (target == 'open') {
        return s == 'open' || sl == 'open';
      }
      return s.contains(target) || sl.contains(target) || target.contains(s) || target.contains(sl);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final filteredSnags = _getFilteredSnags();
        final openCount = _controller.snags.where((s) {
          final st = s.status.toLowerCase();
          return st != 'closed' && st != 'verified';
        }).length;

        return RefreshIndicator(
          onRefresh: _controller.fetchSnags,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Filter & Action Bar matching web portal parity
                Row(
                  children: [
                    // Status Dropdown Filter
                    Expanded(
                      flex: 6,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down, size: 20, color: textSecondary),
                            dropdownColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Inter',
                            ),
                            items: _statusOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text(opt),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Open counter badge (e.g., "2 open")
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2E40) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        "$openCount open",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // + Raise Snag Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showRaiseSheet,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        "Raise Snag",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (_controller.isLoadingSnags)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.snagsError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(_controller.snagsError!, style: TextStyle(color: textSecondary)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _controller.fetchSnags, child: const Text("Retry")),
                      ],
                    ),
                  )
                else if (filteredSnags.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(IconlyLight.document, size: 40, color: textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _selectedStatus == 'All statuses'
                              ? "No snags or defects raised yet."
                              : "No snags found for \"$_selectedStatus\".",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Raise a snag to track defects through to close-out.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredSnags.map((snag) => _buildSnagCard(
                        snag,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSnagCard(
    SnagModel snag, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color textSecondary,
    required bool isDark,
  }) {
    final severityColor = _severityColor(snag.severity);
    final statusColor = _statusColor(snag.statusLabel.isNotEmpty ? snag.statusLabel : snag.status);
    final statusBg = _statusBg(snag.statusLabel.isNotEmpty ? snag.statusLabel : snag.status, isDark);

    final statusText = snag.statusLabel.isNotEmpty ? snag.statusLabel : snag.status;
    final ref = snag.referenceNo.isNotEmpty ? snag.referenceNo : 'DEF-${snag.id}';
    final category = snag.categoryLabel.isNotEmpty ? snag.categoryLabel : snag.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Severity Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    snag.title.isNotEmpty ? snag.title : "Untitled Snag",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: severityColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    snag.severityLabel.isNotEmpty ? snag.severityLabel : snag.severity,
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Reference & Category Subtitle
            Row(
              children: [
                Text(
                  "$ref · $category",
                  style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                ),
                if (snag.linkedPin != null && snag.linkedPin!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text("•", style: TextStyle(color: textSecondary)),
                  const SizedBox(width: 8),
                  Icon(Icons.pin_drop_outlined, size: 12, color: textSecondary),
                  const SizedBox(width: 2),
                  Text(
                    snag.linkedPin!,
                    style: TextStyle(fontSize: 12, color: textSecondary, fontFamily: 'Inter'),
                  ),
                ],
              ],
            ),

            if (snag.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                snag.description,
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.3, fontFamily: 'Inter'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),

            // Metadata Row: Due Date, Assigned To, Status Badge
            Row(
              children: [
                if (snag.dueDate != null) ...[
                  Icon(IconlyLight.calendar, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    "Due ${snag.dueDate!.day.toString().padLeft(2, '0')}/${snag.dueDate!.month.toString().padLeft(2, '0')}/${snag.dueDate!.year}",
                    style: TextStyle(fontSize: 12, color: textSecondary, fontFamily: 'Inter'),
                  ),
                  const SizedBox(width: 12),
                ],
                if (snag.assignedToName.isNotEmpty) ...[
                  Icon(IconlyLight.profile, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      snag.assignedToName,
                      style: TextStyle(fontSize: 12, color: textSecondary, fontFamily: 'Inter'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                
                // Status Badge with dot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark && statusText.toLowerCase().contains('assigned') ? Colors.white : statusColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 12),

            // Actions Row (Open & Delete) with parity to web portal
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Open Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _showSnagDetails(snag),
                  icon: const Icon(IconlyLight.show, size: 16),
                  label: const Text(
                    "Open",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  ),
                ),
                const SizedBox(width: 10),

                // Delete Button (Trash icon)
                IconButton(
                  tooltip: "Delete Snag",
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _confirmDeleteSnag(snag),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RaiseSnagSheet extends StatefulWidget {
  final ProjectIssuesController controller;
  const _RaiseSnagSheet({required this.controller});

  @override
  State<_RaiseSnagSheet> createState() => _RaiseSnagSheetState();
}

class _RaiseSnagSheetState extends State<_RaiseSnagSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categorySpecifyController = TextEditingController();
  final AdminMembersController _membersController = AdminMembersController();

  String _category = 'Other';
  String _severity = 'Low';
  AdminMember? _selectedMember;
  DateTime? _dueDate;
  final List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Other',
    'Design',
    'Safety',
    'Electrical',
    'Plumbing',
    'Structural',
    'Finishes',
    'Joinery',
    'HVAC',
  ];

  final List<String> _severities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void initState() {
    super.initState();
    _membersController.fetchMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categorySpecifyController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await CustomDatePickerDialog.showCustomDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var f in result.files) {
            if (f.path != null) {
              _selectedPhotos.add(File(f.path!));
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking photos: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final payload = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category.toLowerCase(),
      'category_label': _category,
      if (_categorySpecifyController.text.trim().isNotEmpty)
        'category_specify': _categorySpecifyController.text.trim(),
      'severity': _severity.toLowerCase(),
      'severity_label': _severity,
      if (_selectedMember != null) 'assigned_to_id': _selectedMember!.id,
      if (_selectedMember != null) 'assigned_to_name': _selectedMember!.displayName,
      if (_dueDate != null) 'due_date': _dueDate!.toIso8601String().split('T').first,
    };

    final result = await widget.controller.raiseSnag(payload);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Snag saved.'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputBg = isDark ? AppTheme.darkSurface : Colors.grey.shade50;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(IconlyBold.paper, color: Color(0xFF0D6EFD), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Raise Snag",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  color: textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title *
                    _buildFieldLabel("Title *", textColor),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: _inputDecoration(
                        hintText: "Enter snag title",
                        inputBg: inputBg,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? "Title is required" : null,
                    ),
                    const SizedBox(height: 16),

                    // Category & Category (specify)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Category", textColor),
                              DropdownButtonFormField<String>(
                                initialValue: _category,
                                dropdownColor: bg,
                                decoration: _inputDecoration(
                                  inputBg: inputBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                ),
                                style: TextStyle(color: textColor, fontSize: 14),
                                items: _categories
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) => setState(() => _category = val ?? 'Other'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Category (specify)", textColor),
                              TextFormField(
                                controller: _categorySpecifyController,
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: _inputDecoration(
                                  hintText: "e.g. Access issue",
                                  inputBg: inputBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Severity & Assigned To
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Severity", textColor),
                              DropdownButtonFormField<String>(
                                initialValue: _severity,
                                dropdownColor: bg,
                                decoration: _inputDecoration(
                                  inputBg: inputBg,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                ),
                                style: TextStyle(color: textColor, fontSize: 14),
                                items: _severities
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) => setState(() => _severity = val ?? 'Low'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Assigned To", textColor),
                              AnimatedBuilder(
                                animation: _membersController,
                                builder: (context, _) {
                                  final members = _membersController.members;
                                  return DropdownButtonFormField<AdminMember?>(
                                    initialValue: _selectedMember,
                                    dropdownColor: bg,
                                    decoration: _inputDecoration(
                                      inputBg: inputBg,
                                      borderColor: borderColor,
                                      isDark: isDark,
                                    ),
                                    style: TextStyle(color: textColor, fontSize: 13),
                                    isExpanded: true,
                                    hint: Text("Unassigned", style: TextStyle(color: textSecondary, fontSize: 13)),
                                    items: [
                                      const DropdownMenuItem<AdminMember?>(
                                        value: null,
                                        child: Text("Unassigned"),
                                      ),
                                      ...members.map((m) {
                                        return DropdownMenuItem<AdminMember?>(
                                          value: m,
                                          child: Text(
                                            m.displayName.isNotEmpty ? m.displayName : m.email,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) => setState(() => _selectedMember = val),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    _buildFieldLabel("Due Date", textColor),
                    InkWell(
                      onTap: _pickDueDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dueDate == null
                                  ? "dd-mm-yyyy"
                                  : "${_dueDate!.day.toString().padLeft(2, '0')}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.year}",
                              style: TextStyle(
                                color: _dueDate == null ? textSecondary : textColor,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                            Icon(Icons.calendar_today_outlined, size: 18, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildFieldLabel("Description", textColor),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: _inputDecoration(
                        hintText: "What's wrong?",
                        inputBg: inputBg,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photos upload section
                    _buildFieldLabel("Photos", textColor),
                    InkWell(
                      onTap: _pickPhotos,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Choose Files",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedPhotos.isEmpty
                                    ? "No file chosen"
                                    : "${_selectedPhotos.length} photo(s) selected",
                                style: TextStyle(fontSize: 13, color: textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.attach_file, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedPhotos.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final file = entry.value;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPhotos.removeAt(idx);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Raise Snag", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    required Color inputBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 13),
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

class _SnagDetailsDialog extends StatelessWidget {
  final SnagModel snag;
  final ProjectIssuesController controller;
  final VoidCallback onDelete;

  const _SnagDetailsDialog({
    required this.snag,
    required this.controller,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    final ref = snag.referenceNo.isNotEmpty ? snag.referenceNo : 'DEF-${snag.id}';
    final category = snag.categoryLabel.isNotEmpty ? snag.categoryLabel : snag.category;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6EFD),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          snag.title.isNotEmpty ? snag.title : "Snag Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    color: textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),

              // Details Grid
              _buildDetailRow("Category", category, textColor, textSecondary),
              if (snag.categorySpecify != null && snag.categorySpecify!.isNotEmpty)
                _buildDetailRow("Category (specify)", snag.categorySpecify!, textColor, textSecondary),
              _buildDetailRow("Severity", snag.severityLabel.isNotEmpty ? snag.severityLabel : snag.severity, textColor, textSecondary),
              _buildDetailRow("Status", snag.statusLabel.isNotEmpty ? snag.statusLabel : snag.status, textColor, textSecondary),
              _buildDetailRow("Assigned To", snag.assignedToName.isNotEmpty ? snag.assignedToName : "Unassigned", textColor, textSecondary),
              if (snag.dueDate != null)
                _buildDetailRow(
                  "Due Date",
                  "${snag.dueDate!.day.toString().padLeft(2, '0')}/${snag.dueDate!.month.toString().padLeft(2, '0')}/${snag.dueDate!.year}",
                  textColor,
                  textSecondary,
                ),
              if (snag.linkedPin != null && snag.linkedPin!.isNotEmpty)
                _buildDetailRow("Linked Pin", snag.linkedPin!, textColor, textSecondary),

              if (snag.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  "Description",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    snag.description,
                    style: TextStyle(fontSize: 13, color: textColor, height: 1.3),
                  ),
                ),
              ],

              if (snag.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Photos (${snag.photoUrls.length})",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: snag.photoUrls.map((url) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: labelColor, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
