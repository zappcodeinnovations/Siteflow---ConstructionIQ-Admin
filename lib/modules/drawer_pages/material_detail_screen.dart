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
    _tabController.addListener(_onChanged);
    _controller.fetchDetail();
    _controller.fetchDropdownOptions();
    _controller.fetchRateSets(category: _activeCategory);
    _controller.fetchRecycleBin();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _tabController.removeListener(_onChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final material = _controller.material;

    return Scaffold(
      appBar: AppBar(
        title: Text(material?['name']?.toString() ?? 'Material'),
        actions: [
          if (_tabController.index == 2)
            IconButton(
              icon: Badge(
                isLabelVisible: _controller.recycleBinAttachments.isNotEmpty,
                label: Text('${_controller.recycleBinAttachments.length}'),
                child: const Icon(IconlyLight.delete),
              ),
              tooltip: "Recycle Bin",
              onPressed: () => _AttachmentsSection.showRecycleBinBottomSheet(context, _controller),
            ),
        ],
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
  static const _inputTypeChoices = [
    {'value': 'quantity', 'label': 'Quantity'},
    {'value': 'linear_metres', 'label': 'Linear metres'},
    {'value': 'square_metres_width_height', 'label': 'Square metres (width x height)'},
    {'value': 'quantity_and_diameter_mm', 'label': 'Quantity and diameter (mm)'},
    {'value': 'square_metres_4_sides_width_height', 'label': 'Square metres (4 sides width x height)'},
    {'value': 'linear_metres_and_joint_size_mm', 'label': 'Linear metres and joint size (mm)'},
  ];

  late final _nameController = TextEditingController(text: widget.controller.material?['name']?.toString() ?? '');
  late final _manufacturerController = TextEditingController(text: widget.controller.material?['manufacturer']?.toString() ?? '');
  late final _productCodeController = TextEditingController(text: widget.controller.material?['product_code']?.toString() ?? '');
  late final _certRefController = TextEditingController(text: widget.controller.material?['certification_reference']?.toString() ?? '');
  late String _status = widget.controller.material?['status']?.toString() ?? 'active';
  late String? _inputType = widget.controller.material?['input_type']?.toString();
  late int? _materialGroupId = _parseIntOrNull(widget.controller.material?['material_group_id']);
  late final Set<int> _selectedTagIds = ((widget.controller.material?['tags'] as List?) ?? [])
      .whereType<Map>()
      .map((t) => _parseIntOrNull(t['id']) ?? -1)
      .where((id) => id != -1)
      .toSet();

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
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
      if (_inputType != null) "input_type": _inputType,
      if (_materialGroupId != null) "material_group": _materialGroupId,
      "tag_ids": _selectedTagIds.toList(),
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
          DropdownButtonFormField<String>(
            initialValue: _inputTypeChoices.any((c) => c['value'] == _inputType) ? _inputType : null,
            decoration: const InputDecoration(labelText: "Input Type", border: OutlineInputBorder()),
            items: _inputTypeChoices
                .map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) => setState(() => _inputType = val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: widget.controller.groups.any((g) => g['id'] == _materialGroupId) ? _materialGroupId : null,
            decoration: const InputDecoration(labelText: "Material Group", border: OutlineInputBorder()),
            items: widget.controller.groups
                .map((g) => DropdownMenuItem(
                      value: g['id'] is int ? g['id'] as int : int.tryParse(g['id'].toString()),
                      child: Text(g['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _materialGroupId = val),
          ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text("Tags", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.allTags.isEmpty
                ? [Text("No tags available.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))]
                : widget.controller.allTags.map((t) {
                    final id = t['id'] is int ? t['id'] as int : int.tryParse(t['id'].toString()) ?? -1;
                    final selected = _selectedTagIds.contains(id);
                    return FilterChip(
                      label: Text(t['name']?.toString() ?? ''),
                      selected: selected,
                      onSelected: (val) => setState(() {
                        if (val) {
                          _selectedTagIds.add(id);
                        } else {
                          _selectedTagIds.remove(id);
                        }
                      }),
                    );
                  }).toList(),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final minMeasureController = TextEditingController();
    String selectedCategory = activeCategory;
    bool isDefault = false;
    bool isSaving = false;
    String? nameError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final titleColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
          final fieldFill = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white;
          final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row with Title & Close Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Add Rate Set",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.grey.shade600),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category *
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Category ",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                            const TextSpan(
                              text: "*",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: fieldFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: fieldBorder),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(categoryLabels[cat] ?? cat),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name *
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Name ",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                            const TextSpan(
                              text: "*",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "e.g. Standard Rate, Subcontractor",
                          hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          filled: true,
                          fillColor: fieldFill,
                          errorText: nameError,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                        ),
                        onChanged: (val) {
                          if (nameError != null && val.trim().isNotEmpty) {
                            setDialogState(() => nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Minimum Measure
                      Text(
                        "Minimum Measure",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: minMeasureController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "e.g. 0.00",
                          hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          filled: true,
                          fillColor: fieldFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Set as default Checkbox
                      InkWell(
                        onTap: () => setDialogState(() => isDefault = !isDefault),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isDefault,
                                activeColor: const Color(0xFF0D6EFD),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setDialogState(() => isDefault = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Set as default",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Actions: Cancel and Save
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    if (name.isEmpty) {
                                      setDialogState(() => nameError = "Rate set name is required");
                                      return;
                                    }

                                    setDialogState(() => isSaving = true);
                                    final minMeasure = minMeasureController.text.trim();
                                    final result = await controller.createRateSet(
                                      name: name,
                                      category: selectedCategory,
                                      minimumMeasure: minMeasure.isNotEmpty ? minMeasure : null,
                                      isDefault: isDefault,
                                    );

                                    if (!context.mounted) return;
                                    Navigator.pop(dialogContext);

                                    if (selectedCategory != activeCategory) {
                                      onCategoryChanged(selectedCategory);
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ?? ''),
                                        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                      ),
                                    );
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showManageRateSetsModal(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final totalCount = controller.rateSets.length;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(IconlyLight.setting, color: Color(0xFF0D6EFD), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Manage Rate Sets",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                              ),
                            ),
                            Text(
                              "${categoryLabels[activeCategory] ?? activeCategory} · $totalCount configured",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white70 : Colors.grey.shade600),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Category selector inside management modal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = activeCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(categoryLabels[cat] ?? cat),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0D6EFD),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              onCategoryChanged(cat);
                              setSheetState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Rate sets list
                Expanded(
                  child: controller.rateSets.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "No ${categoryLabels[activeCategory] ?? activeCategory} rate sets yet.",
                              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: controller.rateSets.length,
                          itemBuilder: (context, index) {
                            final rateSet = controller.rateSets[index];
                            final tierCount = ((rateSet['tiers'] as List?) ?? []).length;
                            final isDefaultSet = rateSet['is_default'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rateSet['name']?.toString() ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                        ),
                                      ),
                                    ),
                                    if (isDefaultSet)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                        ),
                                        child: const Text(
                                          "Default",
                                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  "$tierCount tier(s) configured",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(IconlyLight.edit, size: 18, color: Color(0xFF0D6EFD)),
                                      tooltip: "Edit Tiers",
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        _editTiers(context, rateSet);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                      tooltip: "Delete Rate Set",
                                      onPressed: () async {
                                        final result = await controller.deleteRateSet(rateSet['id'] as int, activeCategory);
                                        setSheetState(() {});
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

                // Bottom Action
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showAddRateSetDialog(context);
                    },
                    icon: const Icon(IconlyLight.plus, size: 18),
                    label: const Text("Add New Rate Set", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeLabel = categoryLabels[activeCategory] ?? activeCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Section: Header & Action Buttons ("Manage Rate Sets" and "Add Rates")
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rate Sets",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manage Rate Sets Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0D6EFD),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: () => _showManageRateSetsModal(context),
                    icon: const Icon(IconlyLight.setting, size: 16),
                    label: const Text(
                      "Manage Rate Sets",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Add Rates Action Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _showAddRateSetDialog(context),
                    icon: const Icon(IconlyLight.plus, size: 14),
                    label: const Text(
                      "Add Rates",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Category Pills Row (Operative, Material Cost, Charge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = activeCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onCategoryChanged(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1))
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              Icons.check,
                              size: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            categoryLabels[cat] ?? cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F2C4A))
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Main List or Empty State
        Expanded(
          child: controller.rateSets.isEmpty
              ? Center(
                  child: Text(
                    "No $activeLabel rate sets yet.",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.rateSets.length,
                  itemBuilder: (context, index) {
                    final rateSet = controller.rateSets[index];
                    final tierCount = ((rateSet['tiers'] as List?) ?? []).length;
                    final isDefaultSet = rateSet['is_default'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                rateSet['name']?.toString() ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                ),
                              ),
                            ),
                            if (isDefaultSet)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  "Default",
                                  style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "$tierCount tier(s)",
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => _editTiers(context, rateSet),
                        trailing: IconButton(
                          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                          onPressed: () async {
                            final result = await controller.deleteRateSet(rateSet['id'] as int, activeCategory);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? ''),
                                backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom Action Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => _showAddRateSetDialog(context),
              icon: const Icon(IconlyLight.plus, size: 16),
              label: const Text("Add Rate Set", style: TextStyle(fontWeight: FontWeight.w600)),
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

  static Future<void> showRecycleBinBottomSheet(
    BuildContext context,
    AdminMaterialDetailController controller,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final deleted = controller.recycleBinAttachments;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      const Icon(IconlyBold.delete, color: Colors.red, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "Attachments Recycle Bin",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
                      ),
                      if (deleted.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${deleted.length}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: textSecondary),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),

                // Content
                Expanded(
                  child: deleted.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(IconlyLight.delete, size: 48, color: textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  "Recycle bin is empty",
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "No deleted attachments for this material.",
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: deleted.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = deleted[index];
                            final String name = item['name']?.toString() ?? 'Attachment #${item['id']}';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(IconlyLight.paper, size: 22, color: textSecondary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Archived / Deleted",
                                          style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Restore Button
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      final res = await controller.restoreAttachment(item['id'] as int);
                                      setSheetState(() {});
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Restored'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.restore, size: 16),
                                    label: const Text("Restore", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 4),
                                  // Permanent Delete Button
                                  IconButton(
                                    icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                    tooltip: "Delete Permanently",
                                    splashRadius: 16,
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: sheetContext,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: const Text("Permanently Delete?"),
                                          content: Text('Permanently remove "$name"? This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogCtx, false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogCtx, true),
                                              child: const Text("Delete Permanently", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) return;
                                      await controller.purgeAttachment(item['id'] as int);
                                      setSheetState(() {});
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Attachment permanently deleted.")),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;

    return Column(
      children: [
        // Attachments Toolbar with Recycle Bin
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                "Attachments (${attachments.length})",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.grey.shade300 : const Color(0xFF0F2C4A),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => showRecycleBinBottomSheet(context, controller),
                icon: Badge(
                  isLabelVisible: controller.recycleBinAttachments.isNotEmpty,
                  label: Text('${controller.recycleBinAttachments.length}'),
                  child: const Icon(IconlyLight.delete, size: 16),
                ),
                label: const Text("Recycle Bin", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        Expanded(
          child: attachments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconlyLight.paper, size: 48, color: textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          "No attachments uploaded yet.",
                          style: TextStyle(fontSize: 14, color: textSecondary),
                        ),
                        if (controller.recycleBinAttachments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => showRecycleBinBottomSheet(context, controller),
                            icon: const Icon(IconlyLight.delete, size: 16),
                            label: Text(
                              "View Recycle Bin (${controller.recycleBinAttachments.length} items)",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final attachment = attachments[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: borderColor),
                      ),
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(IconlyLight.paper, color: Color(0xFF0D6EFD)),
                        title: Text(
                          attachment['name']?.toString() ?? '',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                        ),
                        trailing: IconButton(
                          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                          tooltip: "Move to Recycle Bin",
                          onPressed: () async {
                            final result = await controller.deleteAttachment(attachment['id'] as int);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? ''),
                                backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => _upload(context),
              icon: const Icon(IconlyLight.upload, size: 18),
              label: const Text("Upload Attachment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }
}
