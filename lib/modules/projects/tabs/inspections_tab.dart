import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_issue_models.dart';
import '../project_issues_controller.dart';

class InspectionsTab extends StatefulWidget {
  final int projectId;
  const InspectionsTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<InspectionsTab> createState() => _InspectionsTabState();
}

class _InspectionsTabState extends State<InspectionsTab> {
  late final ProjectIssuesController _controller = ProjectIssuesController(widget.projectId);

  @override
  void initState() {
    super.initState();
    _controller.fetchInspections();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLogDialog() {
    showDialog(
      context: context,
      builder: (_) => _LogInspectionDialog(controller: _controller),
    );
  }

  void _showCompleteDialog(InspectionModel inspection) {
    showDialog(
      context: context,
      builder: (_) => _CompleteInspectionDialog(controller: _controller, inspection: inspection),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'passed':
        return const Color(0xFF16A34A);
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.fetchInspections,
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
                    onPressed: _showLogDialog,
                    icon: const Icon(IconlyBold.tick_square, size: 18),
                    label: const Text("Log Inspection", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                if (_controller.isLoadingInspections)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.inspectionsError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(_controller.inspectionsError!, style: TextStyle(color: textSecondary)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _controller.fetchInspections, child: const Text("Retry")),
                      ],
                    ),
                  )
                else if (_controller.inspections.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text("No inspections logged yet.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Log a QA/QC inspection with a checklist and pass/fail outcome.",
                            textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ..._controller.inspections.map(
                    (inspection) => _buildInspectionCard(inspection, cardColor, borderColor, textColor, textSecondary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspectionCard(InspectionModel inspection, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
    final statusColor = _statusColor(inspection.status);
    final isPending = inspection.status == 'pending';
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
                child: Text(inspection.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(inspection.statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            inspection.referenceNo + (inspection.drawingLocationReference.isNotEmpty ? " · Pin ${inspection.drawingLocationReference}" : ""),
            style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
          ),
          if (inspection.checklistItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...inspection.checklistItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      item.passed == true
                          ? Icons.check_circle
                          : item.passed == false
                              ? Icons.cancel
                              : Icons.radio_button_unchecked,
                      size: 14,
                      color: item.passed == true
                          ? const Color(0xFF16A34A)
                          : item.passed == false
                              ? const Color(0xFFDC2626)
                              : textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item.label, style: TextStyle(fontSize: 12.5, color: textSecondary))),
                  ],
                ),
              ),
            ),
          ],
          if (inspection.inspectorName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Inspector: ${inspection.inspectorName}", style: TextStyle(fontSize: 11, color: textSecondary)),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _showCompleteDialog(inspection),
                child: const Text("Complete Inspection"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogInspectionDialog extends StatefulWidget {
  final ProjectIssuesController controller;
  const _LogInspectionDialog({required this.controller});

  @override
  State<_LogInspectionDialog> createState() => _LogInspectionDialogState();
}

class _LogInspectionDialogState extends State<_LogInspectionDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _checklistController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required.")));
      return;
    }
    final checklistItems = _checklistController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    setState(() => _isSubmitting = true);
    final result = await widget.controller.logInspection({
      'title': _titleController.text.trim(),
      'notes': _notesController.text.trim(),
      'checklist_items': checklistItems,
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
      title: const Text("Log Inspection"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(
              controller: _checklistController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Checklist items (one per line)", alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: "Notes")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Log"),
        ),
      ],
    );
  }
}

class _CompleteInspectionDialog extends StatefulWidget {
  final ProjectIssuesController controller;
  final InspectionModel inspection;
  const _CompleteInspectionDialog({required this.controller, required this.inspection});

  @override
  State<_CompleteInspectionDialog> createState() => _CompleteInspectionDialogState();
}

class _CompleteInspectionDialogState extends State<_CompleteInspectionDialog> {
  late final Map<String, bool> _passedByLabel = {
    for (final item in widget.inspection.checklistItems) item.label: item.passed ?? false,
  };
  String _overallResult = 'passed';
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final passedLabels = _passedByLabel.entries.where((e) => e.value).map((e) => e.key).toList();
    final result = await widget.controller.completeInspection(widget.inspection.id, {
      'overall_result': _overallResult,
      'passed_labels': passedLabels,
      if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
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
      title: Text("Complete: ${widget.inspection.title}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.inspection.checklistItems.isNotEmpty) ...[
              const Text("Checklist", style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.inspection.checklistItems.map(
                (item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _passedByLabel[item.label] ?? false,
                  onChanged: (val) => setState(() => _passedByLabel[item.label] = val ?? false),
                  title: Text(item.label),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text("Overall Result", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'passed',
                    groupValue: _overallResult,
                    onChanged: (val) => setState(() => _overallResult = val ?? 'passed'),
                    title: const Text("Passed"),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'failed',
                    groupValue: _overallResult,
                    onChanged: (val) => setState(() => _overallResult = val ?? 'passed'),
                    title: const Text("Failed"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: "Notes")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Submit"),
        ),
      ],
    );
  }
}
