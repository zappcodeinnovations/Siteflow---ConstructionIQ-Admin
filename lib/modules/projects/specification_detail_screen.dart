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
                final messenger = ScaffoldMessenger.of(context);
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final options = optionsController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                Navigator.pop(dialogContext);
                final result = await widget.controller.createAttributeDefinition(name: name, attributeType: type, options: options);
                if (!mounted) return;
                messenger.showSnackBar(
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
                                Expanded(child: Text(def['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                                onChanged: (val) => setState(() => _pendingValues[defId] = val),
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
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
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

    final Set<int> selectedMaterialIds = {};
    String searchQuery = '';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final bg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
            final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

            final filteredMaterials = available.where((m) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final name = (m['name'] ?? '').toString().toLowerCase();
              final code = (m['code'] ?? '').toString().toLowerCase();
              return name.contains(q) || code.contains(q);
            }).toList();

            return Dialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Row: Title & Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add Material",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Select materials to link to specification",
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: textSecondary,
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Bar
                    if (available.length > 3) ...[
                      TextField(
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Search materials...",
                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                          prefixIcon: const Icon(IconlyLight.search, size: 18),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            searchQuery = val.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),

                    // Material Items List
                    Expanded(
                      child: filteredMaterials.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(IconlyLight.document, size: 36, color: textSecondary),
                                    const SizedBox(height: 8),
                                    Text(
                                      available.isEmpty ? "All available materials are already linked." : "No matching materials found.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredMaterials.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final material = filteredMaterials[index];
                                final int matId = material['id'] is int ? material['id'] : (int.tryParse('${material['id']}') ?? 0);
                                final isSelected = selectedMaterialIds.contains(matId);
                                final matName = material['name']?.toString() ?? 'Material';
                                final matCode = material['code']?.toString() ?? '';

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isSelected) {
                                          selectedMaterialIds.remove(matId);
                                        } else {
                                          selectedMaterialIds.add(matId);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0D6EFD).withValues(alpha: isDark ? 0.18 : 0.08)
                                            : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF0D6EFD) : borderColor,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Material Icon Box
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF0D6EFD).withValues(alpha: 0.15)
                                                  : (isDark ? Colors.white10 : Colors.grey.shade200),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              IconlyLight.document,
                                              size: 18,
                                              color: isSelected ? const Color(0xFF0D6EFD) : textColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Material Name and Code
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  matName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: textColor,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                                if (matCode.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    matCode,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: textSecondary,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),

                                          // Selection Indicator (Checkbox pill)
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? const Color(0xFF0D6EFD) : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected ? const Color(0xFF0D6EFD) : (isDark ? Colors.white38 : Colors.grey.shade400),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),

                    // Action Footer: Close and Add Selected
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: (selectedMaterialIds.isEmpty || isSubmitting)
                              ? null
                              : () async {
                                  setDialogState(() => isSubmitting = true);
                                  int successCount = 0;
                                  for (final id in selectedMaterialIds) {
                                    final res = await controller.addMaterial(id);
                                    if (res['success'] == true) successCount++;
                                  }
                                  if (!context.mounted) return;
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Linked $successCount material${successCount > 1 ? 's' : ''} successfully."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  selectedMaterialIds.isEmpty
                                      ? "Add Material"
                                      : "Add Selected (${selectedMaterialIds.length})",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = ((controller.spec?['materials'] as List?) ?? []).cast<Map>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    return Column(
      children: [
        Expanded(
          child: materials.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconlyLight.document, size: 48, color: textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          "No materials linked yet.",
                          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap '+ Add Material' below to select and link materials from the library.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 13, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final link = materials[index];
                    final name = link['material_name']?.toString() ?? 'Material';
                    final matId = link['material_id'] as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(IconlyLight.document, color: Color(0xFF0D6EFD), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(IconlyLight.delete, size: 18, color: Colors.redAccent),
                              tooltip: "Remove Material",
                              onPressed: () async {
                                final result = await controller.removeMaterial(matId);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? ''),
                                    backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                  ),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showAddMaterialDialog(context),
              icon: const Icon(IconlyLight.plus, size: 18),
              label: const Text(
                "Add Material",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
              ),
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

  Future<void> _showAddItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController(text: '0.00');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Price Item"),
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
              final result = await controller.addPriceItem(
                name: name,
                quantity: quantityController.text.trim(),
                unitPrice: unitPriceController.text.trim(),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
              );
            },
            child: const Text("Add"),
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
                              icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
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
                  onPressed: () => _showAddItemDialog(context),
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
