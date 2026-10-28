import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'method_statement_templates_controller.dart';

/// Mobile counterpart of the web's Method Statement Templates page, reached
/// from the RAMS Builder's "Manage Templates" link so a template can be
/// created/edited/archived without leaving the app.
class MethodStatementTemplatesScreen extends StatefulWidget {
  const MethodStatementTemplatesScreen({super.key});

  @override
  State<MethodStatementTemplatesScreen> createState() => _MethodStatementTemplatesScreenState();
}

class _MethodStatementTemplatesScreenState extends State<MethodStatementTemplatesScreen> {
  final _controller = MethodStatementTemplatesController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.fetchTemplates();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleActive(Map<String, dynamic> template) async {
    final isActive = template['is_active'] == true;
    final error = await _controller.setActive(template['id'] as int, !isActive);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showEditDialog({Map<String, dynamic>? template}) async {
    final fields = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _TemplateFormDialog(template: template),
    );

    if (fields == null || !mounted) return;

    final String? error = template == null
        ? await _controller.createTemplate(
            title: fields['title']!,
            tradeCategory: fields['trade_category']!,
            ppeRequired: fields['ppe_required']!,
            sequenceOfWork: fields['sequence_of_work']!,
          )
        : await _controller.updateTemplate(
            id: template['id'] as int,
            title: fields['title']!,
            tradeCategory: fields['trade_category']!,
            ppeRequired: fields['ppe_required']!,
            sequenceOfWork: fields['sequence_of_work']!,
          );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Template saved"), backgroundColor: Colors.green),
    );
  }

  Widget _templateCard(Map<String, dynamic> template) {
    final isActive = template['is_active'] == true;
    final tradeCategory = template['trade_category']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(template['title']?.toString() ?? ''),
        subtitle: tradeCategory.isNotEmpty ? Text(tradeCategory) : null,
        onTap: () => _showEditDialog(template: template),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(IconlyLight.edit, size: 18),
              onPressed: () => _showEditDialog(template: template),
              tooltip: "Edit",
            ),
            IconButton(
              icon: Icon(
                isActive ? IconlyLight.delete : Icons.restore,
                size: 18,
                color: isActive ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleActive(template),
              tooltip: isActive ? "Archive" : "Restore",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Templates")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        tooltip: "Add Template",
        child: const Icon(Icons.add),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _controller.fetchTemplates,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_controller.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_controller.error!, style: const TextStyle(color: Colors.red)),
                    ),
                  Text("Active", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_controller.active.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text("No active templates yet.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._controller.active.map(_templateCard),
                  const Divider(height: 24),
                  Text("Archived", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_controller.archived.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text("No archived templates.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._controller.archived.map(_templateCard),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _TemplateFormDialog extends StatefulWidget {
  final Map<String, dynamic>? template;
  const _TemplateFormDialog({this.template});

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _tradeController;
  late final TextEditingController _ppeController;
  late final TextEditingController _sequenceController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template?['title']?.toString() ?? '');
    _tradeController = TextEditingController(text: widget.template?['trade_category']?.toString() ?? '');
    _ppeController = TextEditingController(text: widget.template?['ppe_required']?.toString() ?? '');
    _sequenceController = TextEditingController(text: widget.template?['sequence_of_work']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tradeController.dispose();
    _ppeController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'trade_category': _tradeController.text.trim(),
      'ppe_required': _ppeController.text.trim(),
      'sequence_of_work': _sequenceController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template == null ? "Add Template" : "Edit Template"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title *"),
                validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tradeController,
                decoration: const InputDecoration(labelText: "Trade category"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ppeController,
                decoration: const InputDecoration(labelText: "PPE required"),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sequenceController,
                decoration: const InputDecoration(labelText: "Sequence of work"),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text("Save"),
        ),
      ],
    );
  }
}
