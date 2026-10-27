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
    final titleController = TextEditingController(text: template?['title']?.toString() ?? '');
    final tradeController = TextEditingController(text: template?['trade_category']?.toString() ?? '');
    final ppeController = TextEditingController(text: template?['ppe_required']?.toString() ?? '');
    final sequenceController = TextEditingController(text: template?['sequence_of_work']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(template == null ? "Add Template" : "Edit Template"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title *"),
                    validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: tradeController,
                    decoration: const InputDecoration(labelText: "Trade category"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ppeController,
                    decoration: const InputDecoration(labelText: "PPE required"),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sequenceController,
                    decoration: const InputDecoration(labelText: "Sequence of work"),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final String? error = template == null
                    ? await _controller.createTemplate(
                        title: titleController.text.trim(),
                        tradeCategory: tradeController.text.trim(),
                        ppeRequired: ppeController.text.trim(),
                        sequenceOfWork: sequenceController.text.trim(),
                      )
                    : await _controller.updateTemplate(
                        id: template['id'] as int,
                        title: titleController.text.trim(),
                        tradeCategory: tradeController.text.trim(),
                        ppeRequired: ppeController.text.trim(),
                        sequenceOfWork: sequenceController.text.trim(),
                      );
                if (!dialogContext.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    tradeController.dispose();
    ppeController.dispose();
    sequenceController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template saved"), backgroundColor: Colors.green),
      );
    }
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
