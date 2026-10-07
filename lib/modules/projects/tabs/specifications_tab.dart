import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../specification_controller.dart';
import '../specification_detail_screen.dart';

/// Real specifications list (name/code/price/location count/total value),
/// replacing the generic DynamicTab that always rendered empty since the
/// backend never populated an all-in-one "specifications" key at all.
class SpecificationsTab extends StatefulWidget {
  final int projectId;

  const SpecificationsTab({super.key, required this.projectId});

  @override
  State<SpecificationsTab> createState() => _SpecificationsTabState();
}

class _SpecificationsTabState extends State<SpecificationsTab> {
  late final SpecificationController _controller = SpecificationController(widget.projectId);
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.fetchSpecifications();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add Specification", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(labelText: "Code (optional)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              final result = await _controller.createSpecification(name, codeController.text.trim());
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
              );
              if (result['success'] == true && result['data'] != null) {
                final spec = (result['data'] as Map).cast<String, dynamic>();
                _openDetail(spec['id'] as int);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> spec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Specification"),
        content: Text('Delete "${spec['name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _controller.deleteSpecification(spec['id'] as int);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  void _openDetail(int specId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpecificationDetailScreen(projectId: widget.projectId, specId: specId),
      ),
    ).then((_) => _controller.fetchSpecifications());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "Search specifications…",
                    prefixIcon: const Icon(IconlyLight.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onSubmitted: (val) => _controller.fetchSpecifications(search: val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
                onPressed: _showAddDialog,
                icon: const Icon(IconlyLight.plus, size: 16),
                label: const Text("Add"),
              ),
            ],
          ),
        ),
        Expanded(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null
                  ? Center(child: Text(_controller.error!, style: const TextStyle(color: Colors.red)))
                  : _controller.specifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(IconlyLight.document, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No specifications yet.", style: TextStyle(color: textSecondary, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _controller.specifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final spec = _controller.specifications[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openDetail(spec['id'] as int),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(spec['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${spec['code']?.toString().isNotEmpty == true ? '${spec['code']} · ' : ''}${spec['location_count'] ?? 0} location(s)",
                                            style: TextStyle(fontSize: 12, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text("£${spec['total_value'] ?? '0.00'}", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                    IconButton(
                                      icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                      onPressed: () => _confirmDelete(spec),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
