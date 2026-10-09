import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/library_form_model.dart';
import '../../models/library_template_model.dart';
import '../../models/project_material_model.dart';
import 'library_controller.dart';
import 'admin_material_controller.dart';
import 'material_detail_screen.dart';
import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  final LibraryController _controller = LibraryController();
  final AdminMaterialController _materialController = AdminMaterialController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _controller.fetchForms();
    _controller.fetchMaterials();
    _controller.fetchTemplates();
    _controller.fetchWorkTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Forms"),
            Tab(text: "Materials"),
            Tab(text: "Templates"),
            Tab(text: "Work Types"),
          ],
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark))),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildFormsTab(isDark),
                  _buildMaterialsTab(isDark),
                  _buildTemplatesTab(isDark),
                  _buildWorkTypesTab(isDark),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 3
          ? FloatingActionButton.extended(
              onPressed: () => _showAddWorkTypeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Add Work Type"),
            )
          : (_tabController.index == 1 && !_materialSelectMode)
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddMaterialDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Material"),
                )
              : null,
    );
  }

  Future<void> _showAddMaterialDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    List<Map<String, dynamic>> groups = [];
    List<Map<String, dynamic>> projects = [];

    try {
      final resGroups = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/material-groups/');
      final decodedGroups = jsonDecode(resGroups.body);
      if (decodedGroups['status'] == true && decodedGroups['data'] is List) {
        groups = (decodedGroups['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}

    try {
      final resProjects = await ApiClient.get('${ApiEndpoints.baseUrl}${ApiEndpoints.projects}');
      final decodedProjects = jsonDecode(resProjects.body);
      if (decodedProjects['status'] == true && decodedProjects['data'] is List) {
        projects = (decodedProjects['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}

    if (!context.mounted) return;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Create a material group first (Settings > Materials).")),
      );
      return;
    }

    final nameController = TextEditingController();
    final tagsController = TextEditingController(text: 'Euro');
    final manufacturerController = TextEditingController();
    final productCodeController = TextEditingController();
    final certRefController = TextEditingController();

    int? selectedGroupId = groups.isNotEmpty ? groups.first['id'] as int : null;
    String selectedInputType = 'quantity';
    int? selectedProjectId;
    bool addToAllProjects = false;
    bool addToAllTemplates = false;
    PlatformFile? certDocFile;
    List<PlatformFile> attachedFiles = [];
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildLabel(String text, {bool isRequired = false}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    text,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  if (isRequired)
                    const Text(" *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            );
          }

          final inputDecoration = InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.5)),
          );

          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Text(
                          "Add Material",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: textSecondary),
                          splashRadius: 18,
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),

                  // Scrollable Form Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Material Name *
                          buildLabel("Material Name", isRequired: true),
                          TextField(
                            controller: nameController,
                            autofocus: true,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration.copyWith(hintText: "Enter material name"),
                          ),
                          const SizedBox(height: 14),

                          // Input Type
                          buildLabel("Input Type"),
                          DropdownButtonFormField<String>(
                            initialValue: selectedInputType,
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration,
                            items: const [
                              DropdownMenuItem(value: 'quantity', child: Text("Quantity")),
                              DropdownMenuItem(value: 'linear_metres', child: Text("Linear Metres")),
                              DropdownMenuItem(value: 'square_metres_width_height', child: Text("Square Metres (W x H)")),
                              DropdownMenuItem(value: 'quantity_and_diameter_mm', child: Text("Quantity & Diameter (mm)")),
                              DropdownMenuItem(value: 'square_metres_4_sides_width_height', child: Text("Square Metres (4 sides)")),
                              DropdownMenuItem(value: 'linear_metres_and_joint_size_mm', child: Text("Linear Metres & Joint Size (mm)")),
                            ],
                            onChanged: isSubmitting ? null : (val) => setDialogState(() => selectedInputType = val ?? selectedInputType),
                          ),
                          const SizedBox(height: 14),

                          // Group *
                          buildLabel("Group", isRequired: true),
                          DropdownButtonFormField<int>(
                            initialValue: selectedGroupId,
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration,
                            items: groups
                                .map((g) => DropdownMenuItem(
                                      value: g['id'] as int,
                                      child: Text(g['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: isSubmitting ? null : (val) => setDialogState(() => selectedGroupId = val),
                          ),
                          const SizedBox(height: 14),

                          // Tags
                          buildLabel("Tags"),
                          TextField(
                            controller: tagsController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration.copyWith(hintText: "e.g. Euro"),
                          ),
                          const SizedBox(height: 14),

                          // Manufacturer
                          buildLabel("Manufacturer"),
                          TextField(
                            controller: manufacturerController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration.copyWith(hintText: "e.g. Nullifire"),
                          ),
                          const SizedBox(height: 14),

                          // Product Code
                          buildLabel("Product Code"),
                          TextField(
                            controller: productCodeController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration.copyWith(hintText: "e.g. FS702"),
                          ),
                          const SizedBox(height: 14),

                          // Certification Reference
                          buildLabel("Certification Reference"),
                          TextField(
                            controller: certRefController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration.copyWith(hintText: "e.g. BS EN 1366-3"),
                          ),
                          const SizedBox(height: 14),

                          // Certification Document
                          buildLabel("Certification Document"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                    foregroundColor: textColor,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final result = await FilePicker.platform.pickFiles();
                                          if (result != null && result.files.isNotEmpty) {
                                            setDialogState(() => certDocFile = result.files.first);
                                          }
                                        },
                                  child: const Text("Choose File", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    certDocFile?.name ?? "No file chosen",
                                    style: TextStyle(fontSize: 12, color: certDocFile != null ? textColor : textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (certDocFile != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    splashRadius: 14,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: isSubmitting ? null : () => setDialogState(() => certDocFile = null),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Attachments
                          buildLabel("Attachments"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                    foregroundColor: textColor,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                                          if (result != null && result.files.isNotEmpty) {
                                            setDialogState(() => attachedFiles = result.files);
                                          }
                                        },
                                  child: const Text("Choose Files", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    attachedFiles.isEmpty
                                        ? "No file chosen"
                                        : "${attachedFiles.length} file${attachedFiles.length == 1 ? '' : 's'} chosen",
                                    style: TextStyle(fontSize: 12, color: attachedFiles.isNotEmpty ? textColor : textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (attachedFiles.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    splashRadius: 14,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: isSubmitting ? null : () => setDialogState(() => attachedFiles.clear()),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Assign to Project
                          buildLabel("Assign to Project"),
                          DropdownButtonFormField<int?>(
                            initialValue: selectedProjectId,
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: inputDecoration,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text("Not assigned yet"),
                              ),
                              ...projects.map((p) => DropdownMenuItem<int?>(
                                    value: p['id'] as int,
                                    child: Text(p['name']?.toString() ?? 'Project #${p['id']}', overflow: TextOverflow.ellipsis),
                                  )),
                            ],
                            onChanged: isSubmitting ? null : (val) => setDialogState(() => selectedProjectId = val),
                          ),
                          const SizedBox(height: 12),

                          // Bulk Assignment Checkboxes
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Add to all existing projects", style: TextStyle(fontSize: 13, color: textColor)),
                            value: addToAllProjects,
                            onChanged: isSubmitting ? null : (val) => setDialogState(() => addToAllProjects = val ?? false),
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Add to all existing templates", style: TextStyle(fontSize: 13, color: textColor)),
                            value: addToAllTemplates,
                            onChanged: isSubmitting ? null : (val) => setDialogState(() => addToAllTemplates = val ?? false),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(height: 1, color: borderColor),

                  // Modal Footer Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                          child: Text("Cancel", style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F62FE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Material Name is required.")),
                                    );
                                    return;
                                  }
                                  if (selectedGroupId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Group is required.")),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSubmitting = true);

                                  final result = await _materialController.createMaterial(
                                    name: name,
                                    inputType: selectedInputType,
                                    materialGroupId: selectedGroupId!,
                                    tags: tagsController.text.trim(),
                                    manufacturer: manufacturerController.text.trim(),
                                    productCode: productCodeController.text.trim(),
                                    certificationReference: certRefController.text.trim(),
                                    projectId: selectedProjectId,
                                    addToAllProjects: addToAllProjects,
                                    addToAllTemplates: addToAllTemplates,
                                    certificationDocumentPath: certDocFile?.path,
                                    attachmentPaths: attachedFiles.map((f) => f.path).whereType<String>().toList(),
                                  );

                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? ''),
                                      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                    ),
                                  );

                                  if (result['success'] == true) {
                                    await _controller.fetchMaterials();
                                    final created = (result['data'] as Map?)?.cast<String, dynamic>();
                                    if (created != null && mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MaterialDetailScreen(materialId: created['id'] as int),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  "Add Material",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddWorkTypeDialog(BuildContext context) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Work Type"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              final result = await _controller.createWorkType(name);
              if (!mounted) return;
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

  Future<void> _showRenameWorkTypeDialog(BuildContext context, Map<String, dynamic> workType) async {
    final nameController = TextEditingController(text: workType['name']?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Rename Work Type"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              final result = await _controller.renameWorkType(workType['id'] as int, name);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteWorkType(BuildContext context, Map<String, dynamic> workType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Work Type"),
        content: Text('Delete "${workType['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await _controller.deleteWorkType(workType['id'] as int);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  Widget _buildWorkTypesTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    if (_controller.isLoadingWorkTypes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.workTypesError != null) {
      return Center(child: Text(_controller.workTypesError!, style: TextStyle(color: textSecondary)));
    }
    if (_controller.workTypes.isEmpty) {
      return _emptyState(isDark, "No work types yet", "Add one with the button below.");
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.workTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final workType = _controller.workTypes[index];
        final isActive = workType['is_active'] == true;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
          child: ListTile(
            title: Text(workType['name']?.toString() ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
            subtitle: Text(isActive ? "Active" : "Inactive", style: TextStyle(color: isActive ? Colors.green : textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isActive,
                  onChanged: (val) => _controller.toggleWorkType(workType['id'] as int, val),
                ),
                IconButton(
                  icon: const Icon(IconlyLight.edit, size: 18),
                  onPressed: () => _showRenameWorkTypeDialog(context, workType),
                ),
                IconButton(
                  icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                  onPressed: () => _confirmDeleteWorkType(context, workType),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(bool isDark, String title, String subtitle) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState(String message, VoidCallback onRetry) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Center(child: Text(message)),
        const SizedBox(height: 8),
        Center(child: TextButton(onPressed: onRetry, child: const Text("Retry"))),
      ],
    );
  }

  Widget _buildFormsTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    if (_controller.isLoadingForms) return const Center(child: CircularProgressIndicator());
    if (_controller.formsError != null) return _errorState(_controller.formsError!, _controller.fetchForms);
    if (_controller.forms.isEmpty) {
      return _emptyState(isDark, "No library forms yet.", "Forms are created and published from the web admin panel's Library.");
    }
    return RefreshIndicator(
      onRefresh: _controller.fetchForms,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.forms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final LibraryFormModel form = _controller.forms[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(IconlyBold.paper, color: textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        "${form.statusLabel}${form.isPublished ? ' · Published' : ''} · Used in ${form.templateCount} template${form.templateCount == 1 ? '' : 's'}",
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _materialSelectMode = false;
  final Set<int> _selectedMaterialIds = {};

  Future<void> _runBulkAction(String action) async {
    final ids = _selectedMaterialIds.toList();
    if (ids.isEmpty) return;

    int? groupId;
    if (action == 'change_group') {
      List<Map<String, dynamic>> groups = [];
      try {
        final response = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/material-groups/');
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == true) groups = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } catch (_) {}
      if (!mounted || groups.isEmpty) return;
      groupId = await showDialog<int>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text("Move to Group"),
          children: groups
              .map((g) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogContext, g['id'] as int),
                    child: Text(g['name']?.toString() ?? ''),
                  ))
              .toList(),
        ),
      );
      if (groupId == null) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(action == 'archive' ? "Archive Materials" : "Delete Materials"),
          content: Text('${action == 'archive' ? 'Archive' : 'Delete'} ${ids.length} material(s)?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action == 'archive' ? "Archive" : "Delete", style: const TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final result = await _materialController.bulkAction(action: action, materialIds: ids, materialGroupId: groupId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
    if (result['success'] == true) {
      setState(() {
        _selectedMaterialIds.clear();
        _materialSelectMode = false;
      });
      await _controller.fetchMaterials();
    }
  }

  Widget _buildMaterialsTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    if (_controller.isLoadingMaterials) return const Center(child: CircularProgressIndicator());
    if (_controller.materialsError != null) return _errorState(_controller.materialsError!, _controller.fetchMaterials);
    if (_controller.materials.isEmpty) {
      return _emptyState(isDark, "No materials in the catalog yet.", "Materials and rate sets are managed from the web admin panel's Library.");
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _materialSelectMode = !_materialSelectMode;
                  if (!_materialSelectMode) _selectedMaterialIds.clear();
                }),
                icon: Icon(_materialSelectMode ? IconlyLight.close_square : IconlyLight.tick_square, size: 16),
                label: Text(_materialSelectMode ? "Cancel" : "Select"),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.fetchMaterials,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _controller.materials.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final LibraryMaterialModel material = _controller.materials[index];
                final isSelected = _selectedMaterialIds.contains(material.id);
          return Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Material(
                color: Colors.transparent,
                child: ExpansionTile(
                leading: _materialSelectMode
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (val) => setState(() {
                          if (val == true) {
                            _selectedMaterialIds.add(material.id);
                          } else {
                            _selectedMaterialIds.remove(material.id);
                          }
                        }),
                      )
                    : Icon(IconlyBold.bag, color: textColor, size: 18),
                title: Text(material.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                subtitle: Text(
                  [if (material.materialGroup.isNotEmpty) material.materialGroup, material.inputTypeLabel]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                trailing: _materialSelectMode
                    ? null
                    : IconButton(
                        icon: Icon(IconlyLight.edit, size: 18, color: textColor),
                        tooltip: "Edit material",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MaterialDetailScreen(materialId: material.id)),
                          ).then((_) => _controller.fetchMaterials());
                        },
                      ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: material.rateSets.isEmpty
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Text("No rate sets configured.", style: TextStyle(fontSize: 12, color: textSecondary)),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: material.rateSets
                                .map((rs) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        "${rs.categoryLabel} · ${rs.name}${rs.isDefault ? ' (Default)' : ''}",
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
                ),
              ),
            ),
          );
              },
            ),
          ),
        ),
        if (_materialSelectMode && _selectedMaterialIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Text(
                    "${_selectedMaterialIds.length} selected",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _runBulkAction('change_group'),
                    icon: const Icon(IconlyLight.category, size: 16),
                    label: const Text("Move"),
                  ),
                  TextButton.icon(
                    onPressed: () => _runBulkAction('archive'),
                    icon: const Icon(IconlyLight.folder, size: 16),
                    label: const Text("Archive"),
                  ),
                  TextButton.icon(
                    onPressed: () => _runBulkAction('delete'),
                    icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                    label: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTemplatesTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    if (_controller.isLoadingTemplates) return const Center(child: CircularProgressIndicator());
    if (_controller.templatesError != null) return _errorState(_controller.templatesError!, _controller.fetchTemplates);
    if (_controller.templates.isEmpty) {
      return _emptyState(isDark, "No project templates yet.", "Templates are created from the web admin panel's Library.");
    }
    return RefreshIndicator(
      onRefresh: _controller.fetchTemplates,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final LibraryTemplateModel template = _controller.templates[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(IconlyBold.category, color: textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        "${template.statusLabel} · ${template.fieldCount} field${template.fieldCount == 1 ? '' : 's'}",
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      if (template.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(template.description, style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
