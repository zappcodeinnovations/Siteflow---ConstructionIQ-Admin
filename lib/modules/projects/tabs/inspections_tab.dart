import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_issue_models.dart';
import '../project_issues_controller.dart';

class InspectionsTab extends StatefulWidget {
  final int projectId;
  const InspectionsTab({super.key, required this.projectId});

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

  void _showNewInspectionDialog() {
    showDialog(
      context: context,
      builder: (_) => _NewInspectionDialog(controller: _controller),
    );
  }

  void _showCompleteDialog(InspectionModel inspection) {
    showDialog(
      context: context,
      builder: (_) => _CompleteInspectionDialog(controller: _controller, inspection: inspection),
    );
  }

  void _confirmDeleteInspection(InspectionModel inspection) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = inspection.referenceNo.isNotEmpty
        ? (inspection.title.isNotEmpty ? "${inspection.referenceNo} — ${inspection.title}" : inspection.referenceNo)
        : (inspection.title.isNotEmpty ? inspection.title : "this inspection");

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Delete Inspection",
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F2C4A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            "Are you sure you want to delete $displayName? This action cannot be undone.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _controller.deleteInspection(inspection.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message']?.toString() ?? ''),
                      backgroundColor: res['success'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'passed':
        return const Color(0xFF16A34A);
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _selectedStatusFilter = 'All';

  List<InspectionModel> _getFilteredInspections() {
    if (_selectedStatusFilter == 'All') {
      return _controller.inspections;
    }
    final target = _selectedStatusFilter.toLowerCase().trim();
    return _controller.inspections.where((i) {
      final s = i.status.toLowerCase().trim();
      final sl = i.statusLabel.toLowerCase().trim();
      return s == target || sl == target;
    }).toList();
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color textSecondary,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.22 : 0.1)
              : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : accentColor)
                            : textSecondary,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? accentColor : textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        final totalCount = _controller.inspections.length;
        final pendingCount = _controller.inspections.where((i) => i.status.toLowerCase() == 'pending').length;
        final passedCount = _controller.inspections.where((i) => i.status.toLowerCase() == 'passed').length;
        final failedCount = _controller.inspections.where((i) => i.status.toLowerCase() == 'failed').length;
        final displayedInspections = _getFilteredInspections();

        return RefreshIndicator(
          onRefresh: _controller.fetchInspections,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: _showNewInspectionDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        "New Inspection",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Summary Row (Responsive, Single-Line, Uncut text)
                if (!_controller.isLoadingInspections && _controller.inspections.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: "All",
                          count: totalCount,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          accentColor: const Color(0xFF0D6EFD),
                          isSelected: _selectedStatusFilter == 'All',
                          onTap: () => setState(() => _selectedStatusFilter = 'All'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Pending",
                          count: pendingCount,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          accentColor: const Color(0xFFF59E0B),
                          isSelected: _selectedStatusFilter == 'Pending',
                          onTap: () => setState(() => _selectedStatusFilter = _selectedStatusFilter == 'Pending' ? 'All' : 'Pending'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Passed",
                          count: passedCount,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          accentColor: const Color(0xFF16A34A),
                          isSelected: _selectedStatusFilter == 'Passed',
                          onTap: () => setState(() => _selectedStatusFilter = _selectedStatusFilter == 'Passed' ? 'All' : 'Passed'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Failed",
                          count: failedCount,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          textSecondary: textSecondary,
                          accentColor: const Color(0xFFDC2626),
                          isSelected: _selectedStatusFilter == 'Failed',
                          onTap: () => setState(() => _selectedStatusFilter = _selectedStatusFilter == 'Failed' ? 'All' : 'Failed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],

                // Content Area
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
                        Text(
                          "No inspections logged yet.",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Log a QA/QC inspection with a checklist and pass/fail outcome.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else if (displayedInspections.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "No $_selectedStatusFilter inspections found.",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _selectedStatusFilter = 'All'),
                          child: const Text("Show all inspections"),
                        ),
                      ],
                    ),
                  )
                else
                  ...displayedInspections.map(
                    (inspection) => _buildInspectionCard(inspection, cardColor, borderColor, textColor, textSecondary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspectionCard(
    InspectionModel inspection,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color textSecondary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(inspection.statusLabel.isNotEmpty ? inspection.statusLabel : inspection.status);
    final isPending = inspection.status.toLowerCase() == 'pending';

    // Format title matching web admin format: "QA-00002 — testing project"
    String headerTitle = inspection.title;
    if (inspection.referenceNo.isNotEmpty && inspection.title.isNotEmpty) {
      headerTitle = "${inspection.referenceNo} — ${inspection.title}";
    } else if (inspection.referenceNo.isNotEmpty) {
      headerTitle = inspection.referenceNo;
    }

    final timeString = inspection.formattedTimeText;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  headerTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  inspection.statusLabel.isNotEmpty ? inspection.statusLabel : inspection.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metadata Info Row (Pin, Inspector, Timestamp)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (inspection.drawingLocationReference.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.location, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      inspection.drawingLocationReference,
                      style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              if (inspection.inspectorName.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.user, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      inspection.inspectorName,
                      style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              if (timeString.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      inspection.status.toLowerCase() == 'passed' ? IconlyLight.tick_square : IconlyLight.time_circle,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeString,
                      style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),

          // Checklist items
          if (inspection.checklistItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...inspection.checklistItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      item.passed == true
                          ? Icons.check_circle
                          : item.passed == false
                              ? Icons.cancel
                              : Icons.radio_button_unchecked,
                      size: 15,
                      color: item.passed == true
                          ? const Color(0xFF16A34A)
                          : item.passed == false
                              ? const Color(0xFFDC2626)
                              : textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (inspection.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Notes: ${inspection.notes}",
              style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          const SizedBox(height: 10),

          // Card Action Buttons (Delete & Complete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Delete Button matching web interface
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _confirmDeleteInspection(inspection),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      const Text(
                        "Delete",
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isPending)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D6EFD),
                    side: const BorderSide(color: Color(0xFF0D6EFD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _showCompleteDialog(inspection),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Complete Inspection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewInspectionDialog extends StatefulWidget {
  final ProjectIssuesController controller;
  const _NewInspectionDialog({required this.controller});

  @override
  State<_NewInspectionDialog> createState() => _NewInspectionDialogState();
}

class _NewInspectionDialogState extends State<_NewInspectionDialog> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? ''),
        backgroundColor: result['success'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "New Inspection",
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F2C4A),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title *",
                  hintText: "Inspection title",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Title is required.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _checklistController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Checklist items (one per line)",
                  hintText: "Enter checklist items\nEach on a new line",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Notes",
                  hintText: "Optional notes",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EFD),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Create Inspection", style: TextStyle(fontWeight: FontWeight.bold)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? ''),
        backgroundColor: result['success'] == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Complete: ${widget.inspection.title}",
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F2C4A),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
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
            const Text("Overall Result", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _overallResult = 'passed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _overallResult == 'passed'
                            ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _overallResult == 'passed'
                              ? const Color(0xFF16A34A)
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                          width: _overallResult == 'passed' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: _overallResult == 'passed' ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Passed",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _overallResult == 'passed' ? const Color(0xFF16A34A) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _overallResult = 'failed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _overallResult == 'failed'
                            ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _overallResult == 'failed'
                              ? const Color(0xFFDC2626)
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                          width: _overallResult == 'failed' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel,
                            size: 18,
                            color: _overallResult == 'failed' ? const Color(0xFFDC2626) : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Failed",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _overallResult == 'failed' ? const Color(0xFFDC2626) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EFD),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Submit", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
