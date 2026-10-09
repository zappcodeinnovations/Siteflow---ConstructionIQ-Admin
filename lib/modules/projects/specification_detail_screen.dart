import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import 'specification_controller.dart';

class SpecificationDetailScreen extends StatefulWidget {
  final int projectId;
  final int specId;

  const SpecificationDetailScreen({super.key, required this.projectId, required this.specId});

  @override
  State<SpecificationDetailScreen> createState() => _SpecificationDetailScreenState();
}

class _SpecificationDetailScreenState extends State<SpecificationDetailScreen> with SingleTickerProviderStateMixin {
  late final SpecificationDetailController _controller = SpecificationDetailController(widget.projectId, widget.specId);
  late final TabController _tabController = TabController(length: 5, vsync: this);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.fetchAll();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _controller.spec;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.corporateBlue,
        foregroundColor: Colors.white,
        title: Text(spec?['name']?.toString() ?? 'Specification'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Details"),
            Tab(text: "Attributes"),
            Tab(text: "Materials"),
            Tab(text: "Price"),
            Tab(text: "Files"),
          ],
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.error != null
              ? Center(child: Text(_controller.error!, style: const TextStyle(color: Colors.red)))
              : spec == null
                  ? const Center(child: Text("Specification not found."))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _DetailsTab(controller: _controller),
                        _AttributesTab(controller: _controller),
                        _MaterialsTab(controller: _controller),
                        _PriceTab(controller: _controller),
                        _FilesTab(controller: _controller),
                      ],
                    ),
    );
  }
}

class _DetailsTab extends StatefulWidget {
  final SpecificationDetailController controller;
  const _DetailsTab({required this.controller});

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  late final _nameController = TextEditingController(text: widget.controller.spec?['name']?.toString() ?? '');
  late final _codeController = TextEditingController(text: widget.controller.spec?['code']?.toString() ?? '');
  late final _priceController = TextEditingController(text: widget.controller.spec?['price']?.toString() ?? '0.00');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final result = await widget.controller.updateCore(
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      price: _priceController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _codeController, decoration: const InputDecoration(labelText: "Code", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: "Price", prefixText: "£ ", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _isSaving ? null : _save,
            child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Save Changes"),
          ),
        ],
      ),
    );
  }
}

class _AttributesTab extends StatefulWidget {
  final SpecificationDetailController controller;
  const _AttributesTab({required this.controller});

  @override
  State<_AttributesTab> createState() => _AttributesTabState();
}

class _AttributesTabState extends State<_AttributesTab> {
  final Map<int, dynamic> _pendingValues = {};

  String _attributeTypeLabel(String type) {
    switch (type) {
      case 'number':
        return 'Number';
      case 'yes_no':
        return 'Yes / No';
      case 'select':
        return 'Select';
      case 'multiselect':
        return 'Multiselect';
      default:
        return 'Text';
    }
  }

  Future<void> _showAddDefinitionDialog() async {
    final nameController = TextEditingController();
    final optionsController = TextEditingController();
    String type = 'text';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Attribute"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text("Text")),
                  DropdownMenuItem(value: 'number', child: Text("Number")),
                  DropdownMenuItem(value: 'yes_no', child: Text("Yes/No")),
                  DropdownMenuItem(value: 'select', child: Text("Select")),
                  DropdownMenuItem(value: 'multiselect', child: Text("Multiselect")),
                ],
                onChanged: (val) => setDialogState(() => type = val ?? 'text'),
              ),
              if (type == 'select' || type == 'multiselect') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: optionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Options (one per line)", border: OutlineInputBorder()),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final options = optionsController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                Navigator.pop(dialogContext);
                final result = await widget.controller.createAttributeDefinition(name: name, attributeType: type, options: options);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                );
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final result = await widget.controller.saveAttributeValues(_pendingValues.map((k, v) => MapEntry(k.toString(), v)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
    if (result['success'] == true) setState(() => _pendingValues.clear());
  }

  Future<void> _confirmDeleteDefinition(int definitionId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove Attribute"),
        content: Text('Remove "$name" from every specification on this project?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await widget.controller.deleteAttributeDefinition(definitionId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingValues = ((widget.controller.spec?['attributes'] as List?) ?? []).cast<Map>();
    final valueByDefId = {for (final v in existingValues) v['definition_id'] as int: v['value']};
    final definitions = widget.controller.attributeDefinitions;

    return Column(
      children: [
        Expanded(
          child: definitions.isEmpty
              ? const Center(child: Text("No attributes defined for this project yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: definitions.length,
                  itemBuilder: (context, index) {
                    final def = definitions[index];
                    final defId = def['id'] as int;
                    final type = def['attribute_type']?.toString() ?? 'text';
                    final options = ((def['options'] as List?) ?? []).cast<String>();
                    final currentValue = _pendingValues.containsKey(defId) ? _pendingValues[defId] : valueByDefId[defId];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(def['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        _attributeTypeLabel(type),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                                  onPressed: () => _confirmDeleteDefinition(defId, def['name']?.toString() ?? ''),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (type == 'yes_no')
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text("Yes"),
                                value: currentValue == true,
                                onChanged: (val) => setState(() => _pendingValues[defId] = val),
                              )
                            else if (type == 'select')
                              DropdownButtonFormField<String>(
                                initialValue: options.contains(currentValue) ? currentValue as String : null,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  hintText: options.isEmpty ? 'No options configured' : 'Select ${def['name'] ?? 'value'}',
                                ),
                                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                onChanged: options.isEmpty ? null : (val) => setState(() => _pendingValues[defId] = val),
                              )
                            else if (type == 'multiselect')
                              Wrap(
                                spacing: 8,
                                children: options.map((o) {
                                  final selected = (currentValue is List) && currentValue.contains(o);
                                  return FilterChip(
                                    label: Text(o),
                                    selected: selected,
                                    onSelected: (val) {
                                      setState(() {
                                        final list = List<String>.from((currentValue is List ? currentValue : []).cast<String>());
                                        if (val) {
                                          list.add(o);
                                        } else {
                                          list.remove(o);
                                        }
                                        _pendingValues[defId] = list;
                                      });
                                    },
                                  );
                                }).toList(),
                              )
                            else
                              TextFormField(
                                initialValue: currentValue?.toString() ?? '',
                                keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
                                maxLines: def['use_large_text_input'] == true ? 3 : 1,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  hintText: type == 'number' ? 'Enter a number' : 'Enter ${def['name'] ?? 'value'}',
                                ),
                                onChanged: (val) => _pendingValues[defId] = val,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddDefinitionDialog,
                  icon: const Icon(IconlyLight.plus, size: 16),
                  label: const Text("Add Attribute"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
                  onPressed: _pendingValues.isEmpty ? null : _save,
                  child: const Text("Save Values"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final SpecificationDetailController controller;
  const _MaterialsTab({required this.controller});

  Future<void> _showAddMaterialDialog(BuildContext context) async {
    final linked = ((controller.spec?['materials'] as List?) ?? []).cast<Map>().map((m) => m['material_id'] as int).toSet();
    final available = controller.availableMaterials.where((m) => !linked.contains(m['id'])).toList();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Material"),
        content: SizedBox(
          width: 360,
          height: 400,
          child: available.isEmpty
              ? const Center(child: Text("No more materials to add."))
              : ListView.separated(
                  itemCount: available.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final material = available[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            final result = await controller.addMaterial(material['id'] as int);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                            );
                          },
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF0D6EFD).withOpacity(0.1),
                              child: const Icon(IconlyLight.bag, size: 16, color: Color(0xFF0D6EFD)),
                            ),
                            title: Text(material['name']?.toString() ?? ''),
                            trailing: const Icon(IconlyLight.plus, size: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = ((controller.spec?['materials'] as List?) ?? []).cast<Map>();

    return Column(
      children: [
        Expanded(
          child: materials.isEmpty
              ? const Center(child: Text("No materials linked yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final link = materials[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(link['material_name']?.toString() ?? ''),
                        trailing: IconButton(
                          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            final result = await controller.removeMaterial(link['material_id'] as int);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddMaterialDialog(context),
              icon: const Icon(IconlyLight.plus, size: 16),
              label: const Text("Add Material"),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceTab extends StatelessWidget {
  final SpecificationDetailController controller;
  const _PriceTab({required this.controller});

  Future<void> _showItemDialog(BuildContext context, {Map? existing}) async {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    final quantityController = TextEditingController(text: existing?['quantity']?.toString() ?? '1');
    final unitPriceController = TextEditingController(text: existing?['unit_price']?.toString() ?? '0.00');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? "Edit Price Item" : "Add Price Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: quantityController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: unitPriceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Unit Price", prefixText: "£ ", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              final result = isEdit
                  ? await controller.updatePriceItem(
                      itemId: existing['id'] as int,
                      name: name,
                      quantity: quantityController.text.trim(),
                      unitPrice: unitPriceController.text.trim(),
                    )
                  : await controller.addPriceItem(
                      name: name,
                      quantity: quantityController.text.trim(),
                      unitPrice: unitPriceController.text.trim(),
                    );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
              );
            },
            child: Text(isEdit ? "Save" : "Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ((controller.spec?['price_items'] as List?) ?? []).cast<Map>();
    final totalValue = controller.spec?['total_value']?.toString() ?? '0.00';

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text("No price items yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item['name']?.toString() ?? ''),
                        subtitle: Text("${item['quantity']} × £${item['unit_price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("£${item['total']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(IconlyLight.edit, size: 16, color: Color(0xFF0D6EFD)),
                              tooltip: 'Edit',
                              onPressed: () => _showItemDialog(context, existing: item),
                            ),
                            IconButton(
                              icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final result = await controller.deletePriceItem(item['id'] as int);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("£$totalValue", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showItemDialog(context),
                  icon: const Icon(IconlyLight.plus, size: 16),
                  label: const Text("Add Item"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilesTab extends StatelessWidget {
  final SpecificationDetailController controller;
  const _FilesTab({required this.controller});

  Future<void> _uploadFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    final file = result.files.first;
    final uploadResult = await controller.uploadFile(file.path!, file.name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uploadResult['message'] ?? ''), backgroundColor: uploadResult['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = ((controller.spec?['files'] as List?) ?? []).cast<Map>();

    return Column(
      children: [
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text("No files uploaded yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final url = file['file_url']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(IconlyLight.document),
                        title: Text(file['title']?.toString() ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: url.startsWith('http') ? () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) : null,
                              child: const Text("View"),
                            ),
                            IconButton(
                              icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                              onPressed: () async {
                                final result = await controller.deleteFile(file['id'] as int);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
              onPressed: () => _uploadFile(context),
              icon: const Icon(IconlyLight.upload, size: 16),
              label: const Text("Upload File"),
            ),
          ),
        ),
      ],
    );
  }
}
