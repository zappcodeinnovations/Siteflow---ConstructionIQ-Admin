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
import 'job_sheet_webview_screen.dart';
import 'project_template_workspace_screen.dart';
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
  String _formsStatusFilter = 'active';
  final TextEditingController _formsSearchController = TextEditingController();
  String _templatesStatusFilter = 'active';
  final TextEditingController _templatesSearchController = TextEditingController();

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
    _formsSearchController.dispose();
    _templatesSearchController.dispose();
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFormDialog(),
              icon: const Icon(Icons.add),
              label: const Text("Add Form"),
            )
          : _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddTemplateDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Template"),
                )
              : _tabController.index == 3
                  ? FloatingActionButton.extended(
                      onPressed: () => _showAddWorkTypeDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Work Type"),
                    )
                  : (_tabController.index == 1 && !_materialSelectMode)
                      ? FloatingActionButton.extended(
                          onPressed: () => _showAddMaterialDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Material"),
                        )
                      : null,
    );
  }

  Future<void> _showAddMaterialDialog() async {
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

    if (!mounted) return;
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
        builder: (builderContext, setDialogState) {
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
                maxHeight: MediaQuery.of(builderContext).size.height * 0.85,
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
                                    ScaffoldMessenger.of(builderContext).showSnackBar(
                                      const SnackBar(content: Text("Material Name is required.")),
                                    );
                                    return;
                                  }
                                  if (selectedGroupId == null) {
                                    ScaffoldMessenger.of(builderContext).showSnackBar(
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

  Future<void> _showAddWorkTypeDialog() async {
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

  Future<void> _showRenameWorkTypeDialog(Map<String, dynamic> workType) async {
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

  Future<void> _confirmDeleteWorkType(Map<String, dynamic> workType) async {
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
                  onPressed: () => _showRenameWorkTypeDialog(workType),
                ),
                IconButton(
                  icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                  onPressed: () => _confirmDeleteWorkType(workType),
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

  void _openFormWebview(LibraryFormModel form) {
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.userFormHtml(form.id)}';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobSheetWebviewScreen(url: url, title: form.name)),
    );
  }

  Future<void> _confirmDeleteForm(LibraryFormModel form) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Form"),
        content: Text('Are you sure you want to delete "${form.name}"?'),
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
    final result = await _controller.deleteForm(form.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _showAddFormDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    final formNameController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBodyContext, setDialogState) {
          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Text(
                          "New Form",
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
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Form Name",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: formNameController,
                          autofocus: true,
                          style: TextStyle(fontSize: 14, color: textColor),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Form Name",
                            hintStyle: TextStyle(fontSize: 14, color: textSecondary),
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  // Footer Actions
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
                                  final name = formNameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Form Name is required.")),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isSubmitting = true);
                                  final result = await _controller.createForm(name);
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? ''),
                                      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Add Form", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
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

  Widget _buildFormsTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    return Column(
      children: [
        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Status Dropdown
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _formsStatusFilter,
                        dropdownColor: cardColor,
                        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text("Active Forms")),
                          DropdownMenuItem(value: 'archived', child: Text("Archived Forms")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _formsStatusFilter = val);
                            _controller.fetchForms(status: val, search: _formsSearchController.text, page: 1);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search Input
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _formsSearchController,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Search forms",
                          hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                          prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE))),
                        ),
                        onSubmitted: (val) => _controller.fetchForms(status: _formsStatusFilter, search: val, page: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Apply Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _controller.fetchForms(status: _formsStatusFilter, search: _formsSearchController.text, page: 1),
                    child: const Text("Apply", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  // Reset Button
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: textSecondary),
                    tooltip: "Reset Filters",
                    splashRadius: 18,
                    onPressed: () {
                      _formsSearchController.clear();
                      setState(() => _formsStatusFilter = 'active');
                      _controller.fetchForms(status: 'active', search: '', page: 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sub toolbar: + Add Form button & pagination record indicator
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showAddFormDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Form", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(
                    _controller.forms.isEmpty
                        ? "0 of 0"
                        : "${((_controller.formsPage - 1) * _controller.formsPageSize) + 1} - ${((_controller.formsPage - 1) * _controller.formsPageSize) + _controller.forms.length} of ${_controller.formsTotalCount}",
                    style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                  if (_controller.formsTotalCount > _controller.formsPageSize) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _controller.formsPage > 1
                          ? () => _controller.fetchForms(page: _controller.formsPage - 1)
                          : null,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: ((_controller.formsPage * _controller.formsPageSize) < _controller.formsTotalCount)
                          ? () => _controller.fetchForms(page: _controller.formsPage + 1)
                          : null,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Forms List View
        Expanded(
          child: _controller.isLoadingForms
              ? const Center(child: CircularProgressIndicator())
              : _controller.formsError != null
                  ? _errorState(_controller.formsError!, _controller.fetchForms)
                  : _controller.forms.isEmpty
                      ? _emptyState(isDark, "No library forms found.", "Create a new form with the '+ Add Form' button above.")
                      : RefreshIndicator(
                          onRefresh: _controller.fetchForms,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _controller.forms.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final LibraryFormModel form = _controller.forms[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openFormWebview(form),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(IconlyBold.paper, color: textSecondary, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      form.name,
                                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                                                    ),
                                                  ),
                                                  if (form.isPublished) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE6F4EA),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: isDark ? Colors.green.shade700 : Colors.green.shade300),
                                                      ),
                                                      child: Text(
                                                        "Published",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300),
                                                    ),
                                                    child: Text(
                                                      "${form.templateCount} Templates",
                                                      style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                                    ),
                                                  ),
                                                  if (form.formattedCreatedAt.isNotEmpty)
                                                    Text(
                                                      form.formattedCreatedAt,
                                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(IconlyLight.show, size: 20, color: textColor),
                                          tooltip: "View form",
                                          splashRadius: 18,
                                          onPressed: () => _openFormWebview(form),
                                        ),
                                        IconButton(
                                          icon: const Icon(IconlyLight.delete, size: 20, color: Colors.red),
                                          tooltip: "Delete form",
                                          splashRadius: 18,
                                          onPressed: () => _confirmDeleteForm(form),
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
      ],
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
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    return Column(
      children: [
        // Filter & Search Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Status Dropdown
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _templatesStatusFilter,
                        dropdownColor: cardColor,
                        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text("Active Templates")),
                          DropdownMenuItem(value: 'archived', child: Text("Archived Templates")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _templatesStatusFilter = val);
                            _controller.fetchTemplates(status: val, search: _templatesSearchController.text, page: 1);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search Input
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _templatesSearchController,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: "Search templates",
                          hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                          prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          filled: true,
                          fillColor: inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE))),
                        ),
                        onSubmitted: (val) => _controller.fetchTemplates(status: _templatesStatusFilter, search: val, page: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Apply Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _controller.fetchTemplates(status: _templatesStatusFilter, search: _templatesSearchController.text, page: 1),
                    child: const Text("Apply", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  // Reset Button
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: textSecondary),
                    tooltip: "Reset Filters",
                    splashRadius: 18,
                    onPressed: () {
                      _templatesSearchController.clear();
                      setState(() => _templatesStatusFilter = 'active');
                      _controller.fetchTemplates(status: 'active', search: '', page: 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sub toolbar: + Add Template button & pagination record indicator
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showAddTemplateDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add Template", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(
                    _controller.templates.isEmpty
                        ? "0 of 0"
                        : "${((_controller.templatesPage - 1) * _controller.templatesPageSize) + 1} - ${((_controller.templatesPage - 1) * _controller.templatesPageSize) + _controller.templates.length} of ${_controller.templatesTotalCount}",
                    style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                  if (_controller.templatesTotalCount > _controller.templatesPageSize) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _controller.templatesPage > 1
                          ? () => _controller.fetchTemplates(page: _controller.templatesPage - 1)
                          : null,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: ((_controller.templatesPage * _controller.templatesPageSize) < _controller.templatesTotalCount)
                          ? () => _controller.fetchTemplates(page: _controller.templatesPage + 1)
                          : null,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Templates List
        Expanded(
          child: _controller.isLoadingTemplates
              ? const Center(child: CircularProgressIndicator())
              : _controller.templatesError != null
                  ? _errorState(_controller.templatesError!, _controller.fetchTemplates)
                  : _controller.templates.isEmpty
                      ? _emptyState(isDark, "No project templates found.", "Try adjusting filters or tap '+ Add Template' above.")
                      : RefreshIndicator(
                          onRefresh: _controller.fetchTemplates,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _controller.templates.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final LibraryTemplateModel template = _controller.templates[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProjectTemplateWorkspaceScreen(template: template),
                                      ),
                                    ).then((_) => _controller.fetchTemplates());
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(12),
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
                                              Text(
                                                template.name,
                                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${template.statusLabel} · ${template.fieldCount} field${template.fieldCount == 1 ? '' : 's'}",
                                                style: TextStyle(fontSize: 12, color: textSecondary),
                                              ),
                                              if (template.description.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  template.description,
                                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(IconlyLight.show, size: 20, color: textColor),
                                          tooltip: "View workspace",
                                          splashRadius: 18,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProjectTemplateWorkspaceScreen(template: template),
                                              ),
                                            ).then((_) => _controller.fetchTemplates());
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(IconlyLight.edit, size: 18, color: textColor),
                                          tooltip: "Edit template",
                                          splashRadius: 18,
                                          onPressed: () => _showEditTemplateDialog(template),
                                        ),
                                        IconButton(
                                          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                          tooltip: "Delete template",
                                          splashRadius: 18,
                                          onPressed: () => _confirmDeleteTemplate(template),
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
      ],
    );
  }

  Future<void> _showAddTemplateDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedStatus = 'Active';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Text("New Project Template", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: textSecondary),
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Template Name *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            autofocus: true,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "e.g. Fire Stopping",
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("Status", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            dropdownColor: cardColor,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text("Active")),
                              DropdownMenuItem(value: 'Archived', child: Text("Archived")),
                            ],
                            onChanged: (val) => setDialogState(() => selectedStatus = val ?? selectedStatus),
                          ),
                          const SizedBox(height: 14),
                          Text("Description", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 3,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Enter template description",
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
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
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Template Name is required.")),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isSubmitting = true);
                                  final result = await _controller.createTemplate(
                                    name: name,
                                    description: descController.text.trim(),
                                    status: selectedStatus,
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
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Create Template", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Future<void> _showEditTemplateDialog(LibraryTemplateModel template) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    final nameController = TextEditingController(text: template.name);
    final descController = TextEditingController(text: template.description);
    String selectedStatus = template.statusLabel;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Text("Edit Template", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: textSecondary),
                          onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Template Name *", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text("Status", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            dropdownColor: cardColor,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text("Active")),
                              DropdownMenuItem(value: 'Archived', child: Text("Archived")),
                            ],
                            onChanged: (val) => setDialogState(() => selectedStatus = val ?? selectedStatus),
                          ),
                          const SizedBox(height: 14),
                          Text("Description", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 3,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
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
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) return;
                                  setDialogState(() => isSubmitting = true);
                                  final result = await _controller.updateTemplate(
                                    template.id,
                                    name: name,
                                    description: descController.text.trim(),
                                    status: selectedStatus,
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
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Future<void> _confirmDeleteTemplate(LibraryTemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Template"),
        content: Text('Are you sure you want to delete "${template.name}"?'),
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
    final result = await _controller.deleteTemplate(template.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }
}
