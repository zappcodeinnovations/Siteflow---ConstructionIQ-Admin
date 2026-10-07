import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'admin_material_controller.dart';

class MaterialDetailScreen extends StatefulWidget {
  final int materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> with SingleTickerProviderStateMixin {
  late final AdminMaterialDetailController _controller = AdminMaterialDetailController(widget.materialId);
  late final TabController _tabController = TabController(length: 3, vsync: this);

  static const _categories = ['operative', 'material_cost', 'charge'];
  static const _categoryLabels = {'operative': 'Operative', 'material_cost': 'Material Cost', 'charge': 'Charge'};
  String _activeCategory = 'operative';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.fetchDetail();
    _controller.fetchRateSets(category: _activeCategory);
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
    final material = _controller.material;

    return Scaffold(
      appBar: AppBar(
        title: Text(material?['name']?.toString() ?? 'Material'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Details"), Tab(text: "Rate Sets"), Tab(text: "Attachments")],
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.error != null
              ? Center(child: Text(_controller.error!, style: const TextStyle(color: Colors.red)))
              : material == null
                  ? const Center(child: Text("Material not found."))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _DetailsSection(controller: _controller),
                        _RateSetsSection(
                          controller: _controller,
                          categories: _categories,
                          categoryLabels: _categoryLabels,
                          activeCategory: _activeCategory,
                          onCategoryChanged: (cat) {
                            setState(() => _activeCategory = cat);
                            _controller.fetchRateSets(category: cat);
                          },
                        ),
                        _AttachmentsSection(controller: _controller),
                      ],
                    ),
    );
  }
}

class _DetailsSection extends StatefulWidget {
  final AdminMaterialDetailController controller;
  const _DetailsSection({required this.controller});

  @override
  State<_DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<_DetailsSection> {
  late final _nameController = TextEditingController(text: widget.controller.material?['name']?.toString() ?? '');
  late final _manufacturerController = TextEditingController(text: widget.controller.material?['manufacturer']?.toString() ?? '');
  late final _productCodeController = TextEditingController(text: widget.controller.material?['product_code']?.toString() ?? '');
  late final _certRefController = TextEditingController(text: widget.controller.material?['certification_reference']?.toString() ?? '');
  late String _status = widget.controller.material?['status']?.toString() ?? 'active';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _productCodeController.dispose();
    _certRefController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final result = await widget.controller.updateCore({
      "name": _nameController.text.trim(),
      "manufacturer": _manufacturerController.text.trim(),
      "product_code": _productCodeController.text.trim(),
      "certification_reference": _certRefController.text.trim(),
      "status": _status,
    });
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
          Text("Group: ${widget.controller.material?['material_group']?.toString() ?? ''} · Type: ${widget.controller.material?['input_type_label']?.toString() ?? ''}",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(controller: _manufacturerController, decoration: const InputDecoration(labelText: "Manufacturer", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _productCodeController, decoration: const InputDecoration(labelText: "Product Code", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _certRefController, decoration: const InputDecoration(labelText: "Certification Reference", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'active', child: Text("Active")),
              DropdownMenuItem(value: 'archived', child: Text("Archived")),
            ],
            onChanged: (val) => setState(() => _status = val ?? 'active'),
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

class _RateSetsSection extends StatelessWidget {
  final AdminMaterialDetailController controller;
  final List<String> categories;
  final Map<String, String> categoryLabels;
  final String activeCategory;
  final void Function(String) onCategoryChanged;

  const _RateSetsSection({
    required this.controller,
    required this.categories,
    required this.categoryLabels,
    required this.activeCategory,
    required this.onCategoryChanged,
  });

  Future<void> _showAddRateSetDialog(BuildContext context) async {
    final nameController = TextEditingController();
    bool isDefault = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Rate Set"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder())),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Default for this category"),
                value: isDefault,
                onChanged: (val) => setDialogState(() => isDefault = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext);
                final result = await controller.createRateSet(name: name, category: activeCategory, isDefault: isDefault);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                );
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTiers(BuildContext context, Map<String, dynamic> rateSet) async {
    final tiers = ((rateSet['tiers'] as List?) ?? []).map((t) => (t as Map).cast<String, dynamic>()).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(rateSet['name']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: tiers.length,
                    itemBuilder: (context, index) {
                      final tier = tiers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: tier['tier_type']?.toString() ?? 'up_to',
                                      decoration: const InputDecoration(labelText: "Type", isDense: true),
                                      items: const [
                                        DropdownMenuItem(value: 'up_to', child: Text("Up To")),
                                        DropdownMenuItem(value: 'above', child: Text("Above")),
                                      ],
                                      onChanged: (val) => setSheetState(() => tier['tier_type'] = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: tier['threshold_value']?.toString() ?? '',
                                      decoration: const InputDecoration(labelText: "Threshold", isDense: true),
                                      onChanged: (val) => tier['threshold_value'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                    onPressed: () => setSheetState(() => tiers.removeAt(index)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: tier['flat_amount']?.toString() ?? '0',
                                      decoration: const InputDecoration(labelText: "Flat Amount", isDense: true),
                                      onChanged: (val) => tier['flat_amount'] = val,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: tier['per_unit_amount']?.toString() ?? '0',
                                      decoration: const InputDecoration(labelText: "Per Unit Amount", isDense: true),
                                      onChanged: (val) => tier['per_unit_amount'] = val,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setSheetState(() => tiers.add({"tier_type": "up_to", "threshold_value": "", "flat_amount": "0", "per_unit_amount": "0"})),
                        icon: const Icon(IconlyLight.plus, size: 16),
                        label: const Text("Add Tier"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          final result = await controller.saveRateSetTiers(rateSet['id'] as int, activeCategory, tiers);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                          );
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: categories.map((cat) {
              return ChoiceChip(
                label: Text(categoryLabels[cat] ?? cat),
                selected: activeCategory == cat,
                onSelected: (_) => onCategoryChanged(cat),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: controller.rateSets.isEmpty
              ? const Center(child: Text("No rate sets for this category yet."))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.rateSets.length,
                  itemBuilder: (context, index) {
                    final rateSet = controller.rateSets[index];
                    final tierCount = ((rateSet['tiers'] as List?) ?? []).length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(rateSet['name']?.toString() ?? '')),
                            if (rateSet['is_default'] == true) const Chip(label: Text("Default", style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                          ],
                        ),
                        subtitle: Text("$tierCount tier(s)"),
                        onTap: () => _editTiers(context, rateSet),
                        trailing: IconButton(
                          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            final result = await controller.deleteRateSet(rateSet['id'] as int, activeCategory);
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
              onPressed: () => _showAddRateSetDialog(context),
              icon: const Icon(IconlyLight.plus, size: 16),
              label: const Text("Add Rate Set"),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  final AdminMaterialDetailController controller;
  const _AttachmentsSection({required this.controller});

  Future<void> _upload(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    final uploadResult = await controller.uploadAttachment(result.files.first.path!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uploadResult['message'] ?? ''), backgroundColor: uploadResult['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachments = ((controller.material?['attachments'] as List?) ?? []).cast<Map>();

    return Column(
      children: [
        Expanded(
          child: attachments.isEmpty
              ? const Center(child: Text("No attachments uploaded yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = attachments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(IconlyLight.paper),
                        title: Text(attachment['name']?.toString() ?? ''),
                        trailing: IconButton(
                          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            final result = await controller.deleteAttachment(attachment['id'] as int);
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
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
              onPressed: () => _upload(context),
              icon: const Icon(IconlyLight.upload, size: 16),
              label: const Text("Upload Attachment"),
            ),
          ),
        ),
      ],
    );
  }
}
