import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import 'project_approvals_controller.dart';

class ApprovalStagesScreen extends StatefulWidget {
  final ProjectApprovalsController controller;

  const ApprovalStagesScreen({super.key, required this.controller});

  @override
  State<ApprovalStagesScreen> createState() => _ApprovalStagesScreenState();
}

class _ApprovalStagesScreenState extends State<ApprovalStagesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.fetchStages();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _showAddStageDialog() {
    showDialog(
      context: context,
      builder: (context) => AddApprovalStageDialog(controller: widget.controller),
    );
  }

  void _showEditStageDialog(Map<String, dynamic> stage) {
    showDialog(
      context: context,
      builder: (context) => AddApprovalStageDialog(controller: widget.controller, existingStage: stage),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> stage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Approval Stage"),
        content: Text('Delete "${stage['title']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await widget.controller.deleteStage(stage['id'] as int);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.controller.stages;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        iconTheme: IconThemeData(color: colors.onSurface),
        titleSpacing: 0,
        title: Text(
          "Approval Stages",
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.outlineVariant, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                elevation: 0,
              ),
              onPressed: _showAddStageDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Stage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: widget.controller.isLoadingStages
          ? const Center(child: CircularProgressIndicator())
          : widget.controller.stagesError != null
              ? Center(child: Text(widget.controller.stagesError!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Configure declaration stages and signer access for this project.",
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      if (stages.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(IconlyLight.document, size: 48, color: colors.onSurfaceVariant),
                                const SizedBox(height: 16),
                                Text("No approval stages found.", style: TextStyle(color: colors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...stages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stage = entry.value;
                          final signerNames = ((stage['signers'] as List?) ?? []).map((s) => (s as Map)['name']?.toString() ?? '').join(', ');
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.outlineVariant),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header Row: Reorder + Stage Title + Edit & Delete Actions
                                Row(
                                  children: [
                                    // Reorder controls
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(IconlyLight.arrow_up_2, size: 16),
                                          onPressed: index == 0 ? null : () => widget.controller.reorderStage(stage['id'] as int, 'up'),
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: const Icon(IconlyLight.arrow_down_2, size: 16),
                                          onPressed: index == stages.length - 1 ? null : () => widget.controller.reorderStage(stage['id'] as int, 'down'),
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    // Stage Title
                                    Expanded(
                                      child: Text(
                                        stage['title']?.toString() ?? 'Stage ${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: colors.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Action buttons
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.onSurface,
                                        side: BorderSide(color: colors.outlineVariant),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _showEditStageDialog(stage),
                                      icon: const Icon(IconlyLight.edit, size: 14),
                                      label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFDC2626),
                                        side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _confirmDelete(stage),
                                      icon: const Icon(Icons.delete_outline, size: 14),
                                      label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),

                                // Declaration Text (if present)
                                if ((stage['declaration']?.toString() ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      stage['declaration']?.toString() ?? '',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],

                                // Signers Section (Full width, cleanly styled and wrapped)
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2.0),
                                        child: Icon(
                                          IconlyLight.user,
                                          size: 15,
                                          color: Color(0xFF0D6EFD),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: colors.onSurface,
                                              height: 1.4,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: "Signers: ",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D6EFD),
                                                ),
                                              ),
                                              TextSpan(
                                                text: signerNames.isNotEmpty ? signerNames : "No signers assigned",
                                                style: TextStyle(
                                                  color: signerNames.isNotEmpty ? (isDark ? Colors.white70 : Colors.black87) : Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class AddApprovalStageDialog extends StatefulWidget {
  final ProjectApprovalsController controller;
  final Map<String, dynamic>? existingStage;

  const AddApprovalStageDialog({super.key, required this.controller, this.existingStage});

  @override
  State<AddApprovalStageDialog> createState() => _AddApprovalStageDialogState();
}

class _AddApprovalStageDialogState extends State<AddApprovalStageDialog> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.existingStage?['title']?.toString() ?? '');
  late final TextEditingController _declarationController =
      TextEditingController(text: widget.existingStage?['declaration']?.toString() ?? '');

  late final Set<int> _selectedUserIds = (widget.existingStage?['signers'] as List? ?? [])
      .map((s) => (s as Map)['id'] as int)
      .toSet();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _declarationController.dispose();
    super.dispose();
  }

  Future<void> _saveStage() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required.")));
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one user.")));
      return;
    }

    setState(() => _isSaving = true);
    final result = await widget.controller.saveStage(
      stageId: widget.existingStage?['id'] as int?,
      title: _titleController.text.trim(),
      declaration: _declarationController.text.trim(),
      userIds: _selectedUserIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.controller.assignableUsers;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final fieldFillColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50;
    final fieldBorderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
    final labelColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? const BorderSide(color: AppTheme.darkBorder) : BorderSide.none,
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingStage == null ? "Add Approval Stage" : "Edit Approval Stage",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    fontFamily: 'Inter',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: "Title ",
                        style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                        children: const [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: fieldFillColor,
                        hintText: "Enter approval stage title",
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorderColor)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Declaration",
                      style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _declarationController,
                      maxLines: 4,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fieldFillColor,
                        hintText: "Enter the declaration text...",
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: fieldBorderColor)),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        text: "Users That Can Sign ",
                        style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                        children: const [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: fieldFillColor,
                        border: Border.all(color: fieldBorderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setDialogState) {
                          if (users.isEmpty) {
                            return const Center(child: Text("No users found.", style: TextStyle(color: Colors.grey)));
                          }
                          return ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final userId = user['id'] as int;
                              final isSelected = _selectedUserIds.contains(userId);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      _selectedUserIds.remove(userId);
                                    } else {
                                      _selectedUserIds.add(userId);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  color: isSelected ? Colors.blue.withValues(alpha: 0.12) : Colors.transparent,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                        color: isSelected ? const Color(0xFF0D6EFD) : (isDark ? Colors.white54 : Colors.grey.shade400),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          user['name']?.toString() ?? '',
                                          style: TextStyle(
                                            color: isSelected ? const Color(0xFF66B2FF) : textColor,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            fontSize: 13.5,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.grey.shade600, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _saveStage,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Save Stage", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
