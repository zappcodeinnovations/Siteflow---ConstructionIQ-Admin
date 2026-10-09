import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../create_task_controller.dart';
import '../../../models/job_create_setup_model.dart';

/// Bulk-schedule flow: one job per (operative x date) combination, sharing
/// the same reference/forms/site contact/instructions - mirrors the web's
/// project_jobs "Schedule" action, which CreateTaskDialog's single-job
/// create flow doesn't cover.
class ScheduleJobsDialog extends StatefulWidget {
  final int projectId;
  const ScheduleJobsDialog({super.key, required this.projectId});

  @override
  State<ScheduleJobsDialog> createState() => _ScheduleJobsDialogState();
}

class _ScheduleJobsDialogState extends State<ScheduleJobsDialog> {
  late final CreateTaskController _controller = CreateTaskController(selectedProjectId: widget.projectId);

  final _referenceController = TextEditingController();
  final _instructionsController = TextEditingController();

  final Set<String> _selectedOperativeIds = {};
  final Set<int> _selectedFormIds = {};
  final List<DateTime> _selectedDates = [];
  String? _selectedSiteContact;
  bool _withoutSheet = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init(widget.projectId);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _referenceController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final normalized = DateTime(picked.year, picked.month, picked.day);
    if (_selectedDates.any((d) => d == normalized)) return;
    setState(() {
      _selectedDates.add(normalized);
      _selectedDates.sort();
    });
  }

  Future<void> _showOperativesPicker() async {
    final temp = Set<String>.from(_selectedOperativeIds);
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Select Operatives"),
          content: SizedBox(
            width: 360,
            height: 400,
            child: _controller.operatives.isEmpty
                ? const Center(child: Text("No operatives available."))
                : ListView(
                    children: _controller.operatives.map((op) {
                      return CheckboxListTile(
                        value: temp.contains(op.id),
                        title: Text(op.name),
                        subtitle: op.role != null ? Text(op.role!) : null,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              temp.add(op.id);
                            } else {
                              temp.remove(op.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedOperativeIds
                  ..clear()
                  ..addAll(temp));
                Navigator.pop(dialogContext);
              },
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFormsPicker(List<JobFormOptionModel> availableForms) async {
    final temp = Set<int>.from(_selectedFormIds);
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Select Forms"),
          content: SizedBox(
            width: 360,
            height: 400,
            child: availableForms.isEmpty
                ? const Center(child: Text("No forms available."))
                : ListView(
                    children: availableForms.map((f) {
                      return CheckboxListTile(
                        value: temp.contains(f.id),
                        title: Text(f.name),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              temp.add(f.id);
                            } else {
                              temp.remove(f.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedFormIds
                  ..clear()
                  ..addAll(temp));
                Navigator.pop(dialogContext);
              },
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reference is required."), backgroundColor: Colors.red));
      return;
    }
    if (_selectedOperativeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one operative."), backgroundColor: Colors.red));
      return;
    }
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one date."), backgroundColor: Colors.red));
      return;
    }
    if (!_withoutSheet && _selectedFormIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one form."), backgroundColor: Colors.red));
      return;
    }

    final formNames = _controller.setup?.forms
            .where((f) => _selectedFormIds.contains(f.id))
            .map((f) => f.name)
            .toList() ??
        [];

    final result = await _controller.scheduleJobs(
      projectId: widget.projectId,
      reference: reference,
      operativeIds: _selectedOperativeIds.toList(),
      scheduledDates: _selectedDates.map((d) => d.toIso8601String().split('T').first).toList(),
      formNames: formNames,
      withoutSheet: _withoutSheet,
      siteContact: _selectedSiteContact,
      instructions: _instructionsController.text.trim(),
    );

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message']), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableForms = _controller.setup?.forms ?? [];
    final siteContacts = _controller.setup?.siteContacts ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Schedule Jobs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                  IconButton(icon: const Icon(IconlyLight.close_square), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(labelText: "Reference", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              Text("Operatives (${_selectedOperativeIds.length} selected)", style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _controller.isLoadingOperatives ? null : _showOperativesPicker,
                icon: const Icon(IconlyLight.add_user, size: 18),
                label: const Text("Choose Operatives"),
              ),
              const SizedBox(height: 16),

              Text("Dates (${_selectedDates.length} selected)", style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedDates.map((d) => Chip(
                        label: Text('${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'),
                        onDeleted: () => setState(() => _selectedDates.remove(d)),
                      )),
                  ActionChip(
                    avatar: const Icon(IconlyLight.plus, size: 16),
                    label: const Text("Add Date"),
                    onPressed: _addDate,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Without Job Sheet (Daily Diary)"),
                value: _withoutSheet,
                onChanged: (val) => setState(() => _withoutSheet = val),
              ),
              if (!_withoutSheet) ...[
                const SizedBox(height: 8),
                Text("Forms (${_selectedFormIds.length} selected)", style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _controller.isLoadingSetup ? null : () => _showFormsPicker(availableForms),
                  icon: const Icon(IconlyLight.document, size: 18),
                  label: const Text("Choose Forms"),
                ),
              ],
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedSiteContact,
                decoration: const InputDecoration(labelText: "Site Contact (optional)", border: OutlineInputBorder()),
                items: siteContacts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedSiteContact = val),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Instructions (optional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD)),
                  onPressed: _controller.isSubmitting ? null : _submit,
                  child: _controller.isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Schedule Jobs", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
