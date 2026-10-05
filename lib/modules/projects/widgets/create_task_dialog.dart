import 'package:flutter/material.dart';
import '../create_task_controller.dart';

class CreateTaskDialog extends StatefulWidget {
  final int projectId;
  const CreateTaskDialog({super.key, required this.projectId});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late final CreateTaskController _controller = CreateTaskController(widget.projectId);
  final _referenceController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _recordingMethod = 'with_sheet';
  final Set<int> _selectedFormIds = {};
  String? _siteContact;

  @override
  void initState() {
    super.initState();
    _controller.fetchSetup();
    _controller.addListener(_onControllerChanged);
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

  Future<void> _submit() async {
    if (_referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job reference is required.")));
      return;
    }
    if (_recordingMethod == 'with_sheet' && _selectedFormIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one form sheet.")));
      return;
    }
    final result = await _controller.createTask(
      reference: _referenceController.text.trim(),
      recordingMethod: _recordingMethod,
      formIds: _selectedFormIds.toList(),
      siteContact: _siteContact ?? '',
      instructions: _instructionsController.text.trim(),
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Create Task${_controller.setup?.jobNoDisplay.isNotEmpty == true ? ' (${_controller.setup!.jobNoDisplay})' : ''}"),
      content: SizedBox(
        width: double.maxFinite,
        child: _controller.isLoadingSetup
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            : _controller.setupError != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_controller.setupError!),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _controller.fetchSetup, child: const Text("Retry")),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _referenceController,
                          decoration: const InputDecoration(labelText: "Job reference"),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _recordingMethod,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Recording method"),
                          items: const [
                            DropdownMenuItem(
                              value: 'with_sheet',
                              child: Text("With job sheet", overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'without_sheet',
                              child: Text("Without job sheet (Daily Diary)", overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (val) => setState(() => _recordingMethod = val ?? 'with_sheet'),
                        ),
                        if (_recordingMethod == 'with_sheet') ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Form sheets", style: Theme.of(context).textTheme.labelMedium),
                          ),
                          ...(_controller.setup?.forms ?? []).map((form) {
                            final selected = _selectedFormIds.contains(form.id);
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: selected,
                              title: Text(form.name),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => setState(() {
                                if (val == true) {
                                  _selectedFormIds.add(form.id);
                                } else {
                                  _selectedFormIds.remove(form.id);
                                }
                              }),
                            );
                          }),
                        ],
                        const SizedBox(height: 12),
                        if ((_controller.setup?.siteContacts ?? []).isNotEmpty)
                          DropdownButtonFormField<String>(
                            initialValue: _siteContact,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "Site contact (optional)"),
                            items: _controller.setup!.siteContacts
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => _siteContact = val),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _instructionsController,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: "Instructions (optional)"),
                        ),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: _controller.isSubmitting ? null : () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: (_controller.isSubmitting || _controller.isLoadingSetup || _controller.setupError != null) ? null : _submit,
          child: _controller.isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Create"),
        ),
      ],
    );
  }
}
