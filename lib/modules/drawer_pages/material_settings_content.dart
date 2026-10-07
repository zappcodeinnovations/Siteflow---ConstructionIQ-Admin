import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import 'material_settings_controller.dart';

/// Material Groups/Tags management - was a bare "Materials Content"
/// placeholder in settings_screen.dart with no backend or UI at all.
class MaterialSettingsContent extends StatefulWidget {
  final bool isDesktop;

  const MaterialSettingsContent({super.key, required this.isDesktop});

  @override
  State<MaterialSettingsContent> createState() => _MaterialSettingsContentState();
}

class _MaterialSettingsContentState extends State<MaterialSettingsContent> {
  final MaterialSettingsController _controller = MaterialSettingsController();

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
    super.dispose();
  }

  Future<void> _showNameDialog({
    required String title,
    required String actionLabel,
    String initialValue = '',
    required Future<Map<String, dynamic>> Function(String name) onSubmit,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              final result = await onSubmit(name);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
              );
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String label, Future<Map<String, dynamic>> Function() onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Delete $label"),
        content: Text('Delete "$label"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await onConfirm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    if (_controller.isLoading && _controller.groups.isEmpty && _controller.tags.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isDesktop) ...[
            Text("Material Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text("Manage material groups and tags", style: TextStyle(fontSize: 16, color: subtitleColor)),
            const SizedBox(height: 24),
          ],
          _buildSection(
            icon: IconlyLight.category,
            title: "Material Groups",
            items: _controller.groups,
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
            borderColor: borderColor,
            onAdd: () => _showNameDialog(
              title: "Add Material Group",
              actionLabel: "Create",
              onSubmit: (name) => _controller.createGroup(name),
            ),
            onRename: (item) => _showNameDialog(
              title: "Rename Material Group",
              actionLabel: "Save",
              initialValue: item['name']?.toString() ?? '',
              onSubmit: (name) => _controller.renameGroup(item['id'] as int, name),
            ),
            onDelete: (item) => _confirmDelete(item['name']?.toString() ?? '', () => _controller.deleteGroup(item['id'] as int)),
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: IconlyLight.bookmark,
            title: "Material Tags",
            items: _controller.tags,
            cardColor: cardColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
            borderColor: borderColor,
            onAdd: () => _showNameDialog(
              title: "Add Material Tag",
              actionLabel: "Create",
              onSubmit: (name) => _controller.createTag(name),
            ),
            onRename: (item) => _showNameDialog(
              title: "Rename Material Tag",
              actionLabel: "Save",
              initialValue: item['name']?.toString() ?? '',
              onSubmit: (name) => _controller.renameTag(item['id'] as int, name),
            ),
            onDelete: (item) => _confirmDelete(item['name']?.toString() ?? '', () => _controller.deleteTag(item['id'] as int)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> items,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required VoidCallback onAdd,
    required void Function(Map<String, dynamic> item) onRename,
    required void Function(Map<String, dynamic> item) onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: subtitleColor, size: 20),
                    const SizedBox(width: 12),
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: subtitleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text("${items.length}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(IconlyLight.plus, color: Colors.white, size: 16),
                  label: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text("None yet.", style: TextStyle(color: subtitleColor)),
            )
          else
            ...items.map((item) => Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: subtitleColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: Text("${item['material_count'] ?? 0} materials", style: TextStyle(fontSize: 11, color: subtitleColor)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(IconlyLight.edit, size: 16),
                        onPressed: () => onRename(item),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      IconButton(
                        icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                        onPressed: () => onDelete(item),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
