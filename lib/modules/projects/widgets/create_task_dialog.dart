import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../create_task_controller.dart';
import '../../../models/job_create_setup_model.dart';
import '../../../models/project_model.dart';

class CreateTaskDialog extends StatefulWidget {
  final int? projectId;
  const CreateTaskDialog({super.key, this.projectId});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  late final CreateTaskController _controller = CreateTaskController(selectedProjectId: widget.projectId);

  final _referenceController = TextEditingController();
  final _instructionsController = TextEditingController();

  final Set<int> _selectedFormIds = {};
  String? _selectedOperativeId;
  String? _selectedOperativeName;
  String? _selectedSiteContact;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init(widget.projectId);
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

  void _onProjectChanged(int? newProjectId) {
    if (newProjectId == null || newProjectId == _controller.selectedProjectId) return;
    setState(() {
      _selectedFormIds.clear();
      _selectedSiteContact = null;
    });
    _controller.fetchSetupForProject(newProjectId);
  }

  void _showFormsSelectionDialog(BuildContext context, List<JobFormOptionModel> availableForms) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    final Set<int> tempSelected = Set.from(_selectedFormIds);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Select Forms",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
              ),
              content: SizedBox(
                width: 320,
                child: availableForms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "No forms available for this project.",
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableForms.length,
                        itemBuilder: (c, i) {
                          final form = availableForms[i];
                          final isChecked = tempSelected.contains(form.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              form.name,
                              style: TextStyle(color: textColor, fontSize: 14),
                            ),
                            value: isChecked,
                            activeColor: const Color(0xFF0D6EFD),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  tempSelected.add(form.id);
                                } else {
                                  tempSelected.remove(form.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFormIds.clear();
                      _selectedFormIds.addAll(tempSelected);
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_controller.selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a project.")),
      );
      return;
    }

    if (_referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reference is required.")),
      );
      return;
    }

    if (_selectedOperativeName == null && _selectedOperativeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please assign an operative.")),
      );
      return;
    }

    final result = await _controller.createTask(
      projectId: _controller.selectedProjectId!,
      reference: _referenceController.text.trim(),
      formIds: _selectedFormIds.toList(),
      operativeId: _selectedOperativeId,
      operativeName: _selectedOperativeName,
      siteContact: _selectedSiteContact,
      instructions: _instructionsController.text.trim(),
    );

    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? ''),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF2C3E50) : Colors.grey.shade300;
    final inputBg = isDark ? const Color(0xFF152232) : Colors.grey.shade50;

    final availableForms = _controller.setup?.forms ?? [];
    final selectedFormsText = _selectedFormIds.isEmpty
        ? null
        : availableForms
            .where((f) => _selectedFormIds.contains(f.id))
            .map((f) => f.name)
            .join(', ');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header: "Start New Task Online" + Dismiss "x"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Start New Task Online",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: textColor.withValues(alpha: 0.7),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),

            // Scrollable Form Fields
            Flexible(
              child: _controller.isLoadingProjects && _controller.projects.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Project *
                          _buildFieldLabel("Project", isRequired: true, textColor: textColor),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            initialValue: _controller.selectedProjectId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              hintText: "Select project",
                              isDark: isDark,
                              inputBg: inputBg,
                              borderColor: borderColor,
                            ),
                            dropdownColor: bgColor,
                            items: _controller.projects.map((p) {
                              return DropdownMenuItem<int>(
                                value: p.id,
                                child: Text(
                                  "${p.name} (${p.code})",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: _onProjectChanged,
                          ),
                          const SizedBox(height: 16),

                          // 2. Task No / JOB
                          _buildFieldLabel("Task No", isRequired: false, textColor: textColor),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                  ),
                                  child: Text(
                                    "JOB",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _controller.isLoadingSetup
                                      ? const Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : Text(
                                          _controller.setup?.jobNoDisplay.isNotEmpty == true
                                              ? _controller.setup!.jobNoDisplay
                                              : "Auto-generated",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Reference *
                          _buildFieldLabel("Reference", isRequired: true, textColor: textColor),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _referenceController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: _inputDecoration(
                              hintText: "Add Reference",
                              isDark: isDark,
                              inputBg: inputBg,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. Forms
                          _buildFieldLabel("Forms", isRequired: false, textColor: textColor),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: availableForms.isEmpty
                                ? null
                                : () => _showFormsSelectionDialog(context, availableForms),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedFormsText ?? "Select forms",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: selectedFormsText != null
                                            ? textColor
                                            : secondaryTextColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    IconlyLight.arrow_down_2,
                                    size: 16,
                                    color: secondaryTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. Assign Operative *
                          _buildFieldLabel("Assign Operative", isRequired: true, textColor: textColor),
                          const SizedBox(height: 6),
                          _controller.isLoadingOperatives
                              ? Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _selectedOperativeName ?? _selectedOperativeId,
                                  isExpanded: true,
                                  decoration: _inputDecoration(
                                    hintText: "Select operative",
                                    isDark: isDark,
                                    inputBg: inputBg,
                                    borderColor: borderColor,
                                  ),
                                  dropdownColor: bgColor,
                                  items: _controller.operatives.map((op) {
                                    return DropdownMenuItem<String>(
                                      value: op.name,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              op.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: textColor, fontSize: 14),
                                            ),
                                          ),
                                          if (op.role != null && op.role!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                op.role!,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D6EFD),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedOperativeName = val;
                                      final matched = _controller.operatives
                                          .where((o) => o.name == val)
                                          .firstOrNull;
                                      _selectedOperativeId = matched?.id;
                                    });
                                  },
                                ),
                          const SizedBox(height: 16),

                          // 6. Site Contact
                          _buildFieldLabel("Site Contact", isRequired: false, textColor: textColor),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedSiteContact,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              hintText: "Select site contact",
                              isDark: isDark,
                              inputBg: inputBg,
                              borderColor: borderColor,
                            ),
                            dropdownColor: bgColor,
                            items: (_controller.setup?.siteContacts ?? []).map((c) {
                              return DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  c,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSiteContact = val),
                          ),
                          const SizedBox(height: 16),

                          // 7. Instructions
                          _buildFieldLabel("Instructions", isRequired: false, textColor: textColor),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _instructionsController,
                            maxLines: 3,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: _inputDecoration(
                              hintText: "Add instructions that will help the operative",
                              isDark: isDark,
                              inputBg: inputBg,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            Divider(color: isDark ? Colors.white12 : Colors.grey.shade200, height: 1),

            // Modal Actions: Cancel & Create Task
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _controller.isSubmitting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryTextColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _controller.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _controller.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Create Task",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired, required Color textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          const Text(
            " *",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required Color inputBg,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white38 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
      ),
    );
  }
}
