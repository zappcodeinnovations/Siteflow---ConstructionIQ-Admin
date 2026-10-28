import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/widgets/custom_date_picker_dialog.dart';
import '../method_statement_templates_screen.dart';
import '../project_rams_controller.dart';

/// Full RAMS builder - mirrors the web's rams_builder.html/.js: a Risk
/// Assessment's header fields, an optional Method Statement Template link,
/// and a hazard matrix (add/remove rows), saved as one ProjectHSEDocument +
/// RiskAssessment + RiskAssessmentHazard rows via ProjectRamsController.
class RamsBuilderScreen extends StatefulWidget {
  final int projectId;
  final int? documentId;

  const RamsBuilderScreen({super.key, required this.projectId, this.documentId});

  @override
  State<RamsBuilderScreen> createState() => _RamsBuilderScreenState();
}

class _RamsBuilderScreenState extends State<RamsBuilderScreen> {
  late final ProjectRamsController _controller = ProjectRamsController(widget.projectId);

  final _titleController = TextEditingController();
  final _activityController = TextEditingController();
  final _methodStatementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.fetchBuilderData(documentId: widget.documentId).then((_) {
      _titleController.text = _controller.title;
      _activityController.text = _controller.activityDescription;
      _methodStatementController.text = _controller.methodStatementText;
      if (_controller.hazards.isEmpty) {
        setState(() => _controller.hazards.add(ProjectRamsController.emptyHazardRow()));
      }
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _titleController.dispose();
    _activityController.dispose();
    _methodStatementController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required String? current,
    required void Function(String) onPicked,
  }) async {
    final picked = await CustomDatePickerDialog.showCustomDatePicker(
      context: context,
      initialDate: current != null && current.isNotEmpty ? DateTime.tryParse(current) : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      onPicked(
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}",
      );
    }
  }

  Widget _dateField({
    required String label,
    required String? value,
    required void Function(String) onPicked,
  }) {
    return GestureDetector(
      onTap: () => _pickDate(current: value, onPicked: onPicked),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(IconlyLight.calendar)),
        child: Text(value?.isNotEmpty == true ? value! : 'Select date'),
      ),
    );
  }

  Widget _hazardRow(int index) {
    final hazard = _controller.hazards[index];
    return Card(
      // Keyed by the hazard map's own object identity (stable across
      // removeAt(), unlike index) - without this, Flutter reuses each
      // TextFormField's State by position after a delete, so the fields
      // keep showing the OLD row's text while the underlying data has
      // shifted up, making it look like the wrong hazard got deleted.
      key: ObjectKey(hazard),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text("Hazard ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                  onPressed: _controller.hazards.length <= 1
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          setState(() => _controller.hazards.removeAt(index));
                        },
                ),
              ],
            ),
            TextFormField(
              initialValue: hazard['hazard']?.toString() ?? '',
              decoration: const InputDecoration(labelText: "Hazard *"),
              onChanged: (val) => hazard['hazard'] = val,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: hazard['who_might_be_harmed']?.toString() ?? '',
              decoration: const InputDecoration(labelText: "Who might be harmed"),
              onChanged: (val) => hazard['who_might_be_harmed'] = val,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _ratingDropdown('Likelihood', hazard, 'likelihood')),
                const SizedBox(width: 8),
                Expanded(child: _ratingDropdown('Severity', hazard, 'severity')),
                const SizedBox(width: 8),
                _riskScoreBadge(hazard, 'likelihood', 'severity'),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: hazard['existing_controls']?.toString() ?? '',
              decoration: const InputDecoration(labelText: "Existing controls"),
              maxLines: 2,
              onChanged: (val) => hazard['existing_controls'] = val,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _ratingDropdown('Residual likelihood', hazard, 'residual_likelihood')),
                const SizedBox(width: 8),
                Expanded(child: _ratingDropdown('Residual severity', hazard, 'residual_severity')),
                const SizedBox(width: 8),
                _riskScoreBadge(hazard, 'residual_likelihood', 'residual_severity'),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: hazard['further_actions']?.toString() ?? '',
              decoration: const InputDecoration(labelText: "Further actions"),
              maxLines: 2,
              onChanged: (val) => hazard['further_actions'] = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingDropdown(String label, Map<String, dynamic> hazard, String key) {
    final current = hazard[key] is int ? hazard[key] as int : int.tryParse('${hazard[key]}') ?? 1;
    return DropdownButtonFormField<int>(
      initialValue: current,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: const [1, 2, 3, 4, 5]
          .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
          .toList(),
      onChanged: (val) {
        FocusScope.of(context).unfocus();
        setState(() => hazard[key] = val ?? 1);
      },
    );
  }

  Widget _riskScoreBadge(Map<String, dynamic> hazard, String likelihoodKey, String severityKey) {
    final likelihood = hazard[likelihoodKey] is int ? hazard[likelihoodKey] as int : int.tryParse('${hazard[likelihoodKey]}') ?? 1;
    final severity = hazard[severityKey] is int ? hazard[severityKey] as int : int.tryParse('${hazard[severityKey]}') ?? 1;
    final score = likelihood * severity;
    final color = score >= 15 ? Colors.red : (score >= 8 ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _openManageTemplates() async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MethodStatementTemplatesScreen()),
    );
    if (!mounted) return;
    await _controller.fetchBuilderData(documentId: widget.documentId);
  }

  void _applyTemplate(int? templateId) {
    setState(() => _controller.methodStatementTemplateId = templateId);
    if (templateId == null) return;
    final template = _controller.methodStatementTemplates.firstWhere(
      (t) => t['id'] == templateId,
      orElse: () => {},
    );
    final sequence = template['sequence_of_work']?.toString() ?? '';
    if (sequence.isNotEmpty) {
      _methodStatementController.text = sequence;
      _controller.methodStatementText = sequence;
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    _controller.title = _titleController.text.trim();
    _controller.activityDescription = _activityController.text.trim();
    _controller.methodStatementText = _methodStatementController.text.trim();

    if (_controller.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    final error = await _controller.save();
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("RAMS saved"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentId == null ? "Build RAMS" : "Edit RAMS"),
        actions: [
          IconButton(
            icon: _controller.isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            onPressed: _controller.isSaving ? null : _save,
            tooltip: "Save",
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_controller.error!, style: const TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title *"),
                ),
                const SizedBox(height: 12),
                _dateField(
                  label: "Expiry date",
                  value: _controller.expiryDate,
                  onPicked: (val) => setState(() => _controller.expiryDate = val),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Requires sign-off"),
                  value: _controller.requiresAcknowledgment,
                  onChanged: (val) => setState(() => _controller.requiresAcknowledgment = val),
                ),
                const Divider(height: 24),
                Text("Activity", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _activityController,
                  decoration: const InputDecoration(labelText: "Activity description"),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: "Assessment date",
                        value: _controller.assessmentDate,
                        onPicked: (val) => setState(() => _controller.assessmentDate = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField(
                        label: "Review date",
                        value: _controller.reviewDate,
                        onPicked: (val) => setState(() => _controller.reviewDate = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _controller.methodStatementTemplateId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Start from a Method Statement Template"),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text("None")),
                    ..._controller.methodStatementTemplates.map(
                      (t) => DropdownMenuItem<int>(
                        value: t['id'] as int,
                        child: Text(t['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: _applyTemplate,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openManageTemplates,
                    child: const Text("Manage Templates"),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _methodStatementController,
                  decoration: const InputDecoration(labelText: "Method statement"),
                  maxLines: 4,
                ),
                const Divider(height: 24),
                Text("Hazard matrix", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...List.generate(_controller.hazards.length, _hazardRow),
                OutlinedButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _controller.hazards.add(ProjectRamsController.emptyHazardRow()));
                  },
                  icon: const Icon(IconlyLight.plus, size: 16),
                  label: const Text("Add Hazard"),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
