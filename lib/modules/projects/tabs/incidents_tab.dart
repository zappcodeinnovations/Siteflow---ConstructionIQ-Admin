import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_issue_models.dart';
import '../project_issues_controller.dart';

class IncidentsTab extends StatefulWidget {
  final int projectId;
  const IncidentsTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<IncidentsTab> createState() => _IncidentsTabState();
}

class _IncidentsTabState extends State<IncidentsTab> {
  late final ProjectIssuesController _controller = ProjectIssuesController(widget.projectId);

  @override
  void initState() {
    super.initState();
    _controller.fetchIncidents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (_) => _ReportIncidentDialog(controller: _controller),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'closed':
        return const Color(0xFF16A34A);
      case 'investigating':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF0D6EFD);
    }
  }

  String _formatOccurred(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hour12:$min $amPm';
  }

  Future<void> _confirmDelete(IncidentModel incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Incident"),
        content: Text('Delete "${incident.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _controller.deleteIncident(incident.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']?.toString() ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  void _openIncidentDetail(IncidentModel incident) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(incident.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${incident.referenceNo} · ${incident.isNearMiss ? 'Near Miss' : 'Incident'}",
                  style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 8),
              Text("Severity: ${incident.severityLabel}"),
              Text("Status: ${incident.statusLabel}"),
              if (incident.occurredAt != null) Text("Occurred: ${_formatOccurred(incident.occurredAt)}"),
              if (incident.locationText.isNotEmpty) Text("Location: ${incident.locationText}"),
              if (incident.reportedByName.isNotEmpty) Text("Reported by: ${incident.reportedByName}"),
              if (incident.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(incident.description),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Close")),
        ],
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
        return RefreshIndicator(
          onRefresh: _controller.fetchIncidents,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          value: _controller.incidentStatusFilter ?? 'all',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All statuses')),
                            ..._controller.incidentStatusChoices.map(
                              (c) => DropdownMenuItem(value: c['value']?.toString(), child: Text(c['label']?.toString() ?? '')),
                            ),
                          ],
                          onChanged: (val) => _controller.setIncidentStatusFilter(val),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showReportDialog,
                      icon: const Icon(IconlyBold.danger, size: 18),
                      label: const Text("Report Incident", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_controller.isLoadingIncidents)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.incidentsError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(_controller.incidentsError!, style: TextStyle(color: textSecondary)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _controller.fetchIncidents, child: const Text("Retry")),
                      ],
                    ),
                  )
                else if (_controller.incidents.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text("No incidents or near misses reported yet.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Report what happened, when, where, and how severe.",
                            textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ..._controller.incidents.map((incident) => _buildIncidentCard(incident, cardColor, borderColor, textColor, textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncidentCard(IncidentModel incident, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
    final severityColor = _severityColor(incident.severity);
    final statusColor = _statusColor(incident.status);
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
                child: Text(incident.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: severityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(incident.severityLabel, style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(incident.statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("${incident.referenceNo} · ${incident.isNearMiss ? 'Near Miss' : 'Incident'}",
              style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
          if (incident.occurredAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(IconlyLight.time_circle, size: 13, color: textSecondary),
                const SizedBox(width: 4),
                Text(_formatOccurred(incident.occurredAt), style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ],
          if (incident.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(incident.description, style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(IconlyLight.location, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(incident.locationText.isEmpty ? 'No location given' : incident.locationText, style: TextStyle(fontSize: 12, color: textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (incident.reportedByName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text("Reported by ${incident.reportedByName}", style: TextStyle(fontSize: 11, color: textSecondary)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => _openIncidentDetail(incident), child: const Text("Open")),
              IconButton(
                icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                onPressed: () => _confirmDelete(incident),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportIncidentDialog extends StatefulWidget {
  final ProjectIssuesController controller;
  const _ReportIncidentDialog({required this.controller});

  @override
  State<_ReportIncidentDialog> createState() => _ReportIncidentDialogState();
}

class _ReportIncidentDialogState extends State<_ReportIncidentDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _severity = 'low';
  bool _isNearMiss = false;
  bool _isSubmitting = false;
  DateTime _occurredAt = DateTime.now();

  Future<void> _pickOccurredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) return;
    setState(() {
      _occurredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

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
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required.")));
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.controller.reportIncident({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location_text': _locationController.text.trim(),
      'severity': _severity,
      'is_near_miss': _isNearMiss,
      'occurred_at': _occurredAt.toIso8601String(),
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
      title: const Text("Report Incident"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 12),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Location")),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickOccurredAt,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "When did it happen?"),
                child: Text(
                  "${_occurredAt.day.toString().padLeft(2, '0')}/${_occurredAt.month.toString().padLeft(2, '0')}/${_occurredAt.year} "
                  "${(_occurredAt.hour % 12 == 0 ? 12 : _occurredAt.hour % 12)}:${_occurredAt.minute.toString().padLeft(2, '0')} "
                  "${_occurredAt.hour >= 12 ? 'PM' : 'AM'}",
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: "Severity"),
              items: _severities.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
              onChanged: (val) => setState(() => _severity = val ?? 'low'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isNearMiss,
              onChanged: (val) => setState(() => _isNearMiss = val ?? false),
              title: const Text("This was a near miss (no actual harm)"),
              controlAffinity: ListTileControlAffinity.leading,
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
              : const Text("Report"),
        ),
      ],
    );
  }
}
