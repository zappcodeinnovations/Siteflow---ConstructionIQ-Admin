import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_issue_models.dart';
import '../project_issues_controller.dart';

class SnagsTab extends StatefulWidget {
  final int projectId;
  const SnagsTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<SnagsTab> createState() => _SnagsTabState();
}

class _SnagsTabState extends State<SnagsTab> {
  late final ProjectIssuesController _controller = ProjectIssuesController(widget.projectId);

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

  void _showRaiseDialog() {
    showDialog(
      context: context,
      builder: (_) => _RaiseSnagDialog(controller: _controller),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.fetchSnags,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showRaiseDialog,
                    icon: const Icon(IconlyBold.paper, size: 18),
                    label: const Text("Raise Snag", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
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
                else if (_controller.snags.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.corporateBlue : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text("No snags or defects raised yet.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Raise a snag to track defects through to close-out.",
                            textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ..._controller.snags.map((snag) => _buildSnagCard(snag, cardColor, borderColor, textColor, textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSnagCard(SnagModel snag, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
    final severityColor = _severityColor(snag.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(snag.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: severityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(snag.severityLabel, style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("${snag.referenceNo} · ${snag.categoryLabel}",
              style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
          if (snag.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(snag.description, style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (snag.dueDate != null) ...[
                Icon(IconlyLight.calendar, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Text("Due ${snag.dueDate!.day.toString().padLeft(2, '0')}/${snag.dueDate!.month.toString().padLeft(2, '0')}/${snag.dueDate!.year}",
                    style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(width: 12),
              ],
              if (snag.assignedToName.isNotEmpty) ...[
                Icon(IconlyLight.profile, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(snag.assignedToName, style: TextStyle(fontSize: 12, color: textSecondary), overflow: TextOverflow.ellipsis)),
              ] else
                const Spacer(),
              Text(snag.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RaiseSnagDialog extends StatefulWidget {
  final ProjectIssuesController controller;
  const _RaiseSnagDialog({required this.controller});

  @override
  State<_RaiseSnagDialog> createState() => _RaiseSnagDialogState();
}

class _RaiseSnagDialogState extends State<_RaiseSnagDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'other';
  String _severity = 'low';
  DateTime? _dueDate;
  bool _isSubmitting = false;

  final _categories = const [
    ('electrical', 'Electrical'),
    ('plumbing', 'Plumbing'),
    ('structural', 'Structural'),
    ('finishes', 'Finishes'),
    ('other', 'Other'),
  ];
  final _severities = const [
    ('low', 'Low'),
    ('medium', 'Medium'),
    ('high', 'High'),
    ('critical', 'Critical'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required.")));
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.controller.raiseSnag({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category,
      'severity': _severity,
      if (_dueDate != null) 'due_date': _dueDate!.toIso8601String().split('T').first,
    });
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result['success'] == true) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Raise Snag"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: "Category"),
              items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
              onChanged: (val) => setState(() => _category = val ?? 'other'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: "Severity"),
              items: _severities.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
              onChanged: (val) => setState(() => _severity = val ?? 'low'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "Due date (optional)"),
                child: Text(_dueDate == null
                    ? "Not set"
                    : "${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}"),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Raise"),
        ),
      ],
    );
  }
}
