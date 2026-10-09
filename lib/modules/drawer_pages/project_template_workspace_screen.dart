import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../models/library_template_model.dart';
import 'project_template_workspace_controller.dart';
import 'job_sheet_webview_screen.dart';
import '../../core/network/api_endpoints.dart';

class ProjectTemplateWorkspaceScreen extends StatefulWidget {
  final LibraryTemplateModel template;

  const ProjectTemplateWorkspaceScreen({
    super.key,
    required this.template,
  });

  @override
  State<ProjectTemplateWorkspaceScreen> createState() => _ProjectTemplateWorkspaceScreenState();
}

class _ProjectTemplateWorkspaceScreenState extends State<ProjectTemplateWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final ProjectTemplateWorkspaceController _controller;
  late final TabController _tabController;

  static const List<String> _tabs = [
    'Details',
    'Forms',
    'Tasks',
    'Locations',
    'Specifications',
    'Materials & Rates',
    'Custom Statuses',
    'Approvals',
    'Folders',
  ];

  @override
  void initState() {
    super.initState();
    _controller = ProjectTemplateWorkspaceController.fromModel(widget.template);
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _controller.fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FB);
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Project Template: ${_controller.templateName}",
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Templates",
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F62FE)),
              label: const Text(
                "Back to Templates",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F62FE)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark))),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Breadcrumb Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text("Dashboard", style: TextStyle(fontSize: 12, color: textSecondary)),
                        Icon(Icons.chevron_right, size: 14, color: textSecondary),
                        Text("Library", style: TextStyle(fontSize: 12, color: textSecondary)),
                        Icon(Icons.chevron_right, size: 14, color: textSecondary),
                        Text("Project Templates", style: TextStyle(fontSize: 12, color: textSecondary)),
                        Icon(Icons.chevron_right, size: 14, color: textSecondary),
                        Text(
                          _controller.templateName,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),

                // Horizontal TabBar
                Container(
                  color: cardColor,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFF0F62FE),
                    unselectedLabelColor: textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    indicatorColor: const Color(0xFF0F62FE),
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),

                Divider(height: 1, color: borderColor),

                // Workspace Tab Views
                Expanded(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDetailsTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildFormsTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildTasksTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildLocationsTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildSpecificationsTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildMaterialsTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildCustomStatusesTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildApprovalsTab(isDark, cardColor, textColor, textSecondary, borderColor),
                          _buildFoldersTab(isDark, cardColor, textColor, textSecondary, borderColor),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 1. Details Tab =================
  Widget _buildDetailsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color textSecondary,
    Color borderColor,
  ) {
    final isActive = _controller.statusLabel.toLowerCase() == 'active';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Edit action
              Row(
                children: [
                  Text(
                    "Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showEditDetailsDialog(),
                    child: const Text("Edit", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 18),

              // Fields in 2 columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Template Name", style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          _controller.templateName,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status", style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE6F4EA))
                                : (isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? (isDark ? Colors.green.shade700 : Colors.green.shade400)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            _controller.statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                  : textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Description", style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    _controller.description.trim().isNotEmpty
                        ? _controller.description
                        : "No description yet.",
                    style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditDetailsDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    final nameCtrl = TextEditingController(text: _controller.templateName);
    final descCtrl = TextEditingController(text: _controller.description);
    String selectedStatus = _controller.statusLabel;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Text("Edit Template Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: textSecondary),
                          onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
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
                            controller: nameCtrl,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputFill,
                              isDense: true,
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
                              filled: true,
                              fillColor: inputFill,
                              isDense: true,
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
                            controller: descCtrl,
                            maxLines: 3,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputFill,
                              isDense: true,
                              hintText: "Enter description",
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
                          onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
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
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  setDialogState(() => isSaving = true);
                                  final result = await _controller.updateTemplateDetails(
                                    name: name,
                                    status: selectedStatus,
                                    descriptionText: descCtrl.text.trim(),
                                  );
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message'] ?? 'Saved'),
                                      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                          child: isSaving
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

  // ================= 2. Forms Tab =================
  Widget _buildFormsTab(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color textSecondary,
    Color borderColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Row(
                children: [
                  Text("Forms", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showSelectFormDialog(),
                    child: const Text("Select Form", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Attach one or more library forms to this template.",
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),

              // Attached Forms List
              if (_controller.isLoadingForms)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_controller.attachedForms.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(IconlyLight.paper, size: 36, color: textSecondary),
                      const SizedBox(height: 8),
                      Text("No forms attached to this template yet.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 4),
                      Text("Tap 'Select Form' above to link library forms.", style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controller.attachedForms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final form = _controller.attachedForms[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(IconlyBold.paper, size: 20, color: textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              form.name,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                            ),
                          ),
                          IconButton(
                            icon: Icon(IconlyLight.show, size: 18, color: textColor),
                            tooltip: "Preview Form",
                            splashRadius: 16,
                            onPressed: () {
                              final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.userFormHtml(form.id)}';
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => JobSheetWebviewScreen(url: url, title: form.name)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                            tooltip: "Detach Form",
                            splashRadius: 16,
                            onPressed: () => _controller.detachForm(form.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSelectFormDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Text("Select Library Form", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: textSecondary),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Expanded(
                child: _controller.availableLibraryForms.isEmpty
                    ? Center(
                        child: Text("No library forms found.", style: TextStyle(color: textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _controller.availableLibraryForms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final form = _controller.availableLibraryForms[index];
                          final isAttached = _controller.attachedForms.any((f) => f.id == form.id);
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: ListTile(
                              leading: Icon(IconlyBold.paper, color: const Color(0xFF0F62FE), size: 20),
                              title: Text(form.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                              subtitle: Text("${form.templateCount} Templates", style: TextStyle(fontSize: 12, color: textSecondary)),
                              trailing: isAttached
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F62FE),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () {
                                        _controller.attachForm(form);
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text("Select", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 3. Tasks Tab =================
  Widget _buildTasksTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Tasks",
      subtitle: "Pre-configured tasks for projects instantiated from this template.",
      actionLabel: "+ Add Task",
      onAction: () => _showAddSimpleItemDialog("Add Task", "Task Title", "Description", (title, desc) => _controller.addTask(title, desc)),
      isLoading: _controller.isLoadingTasks,
      items: _controller.tasks,
      itemBuilder: (item) => ListTile(
        leading: const Icon(IconlyLight.tick_square, color: Color(0xFF0F62FE), size: 20),
        title: Text(item['title']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: (item['description']?.toString() ?? '').isNotEmpty ? Text(item['description'], style: TextStyle(fontSize: 12, color: textSecondary)) : null,
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteTask(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // ================= 4. Locations Tab =================
  Widget _buildLocationsTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Locations",
      subtitle: "Pre-set zones, floors, and rooms for this template.",
      actionLabel: "+ Add Location",
      onAction: () => _showAddSimpleItemDialog("Add Location", "Location Name", "Type (e.g. Zone, Floor)", (name, type) => _controller.addLocation(name, type)),
      isLoading: _controller.isLoadingLocations,
      items: _controller.locations,
      itemBuilder: (item) => ListTile(
        leading: const Icon(IconlyLight.location, color: Color(0xFF0F62FE), size: 20),
        title: Text(item['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(item['type']?.toString() ?? 'Zone', style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteLocation(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // ================= 5. Specifications Tab =================
  Widget _buildSpecificationsTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Specifications",
      subtitle: "Specifications assigned to this project template.",
      actionLabel: "+ Add Specification",
      onAction: () => _showAddSimpleItemDialog("Add Specification", "Specification Name", "Code (e.g. SPEC-01)", (name, code) => _controller.addSpecification(name, code ?? '')),
      isLoading: _controller.isLoadingSpecifications,
      items: _controller.specifications,
      itemBuilder: (item) => ListTile(
        leading: const Icon(IconlyLight.document, color: Color(0xFF0F62FE), size: 20),
        title: Text(item['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(item['code']?.toString() ?? '', style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteSpecification(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // ================= 6. Materials & Rates Tab =================
  Widget _buildMaterialsTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Materials & Rates",
      subtitle: "Materials and default rates linked to this template.",
      actionLabel: "+ Add Material",
      onAction: () => _showAddSimpleItemDialog("Add Material", "Material Name", "Group", (name, grp) => _controller.addMaterial(name, grp ?? 'General')),
      isLoading: _controller.isLoadingMaterials,
      items: _controller.materials,
      itemBuilder: (item) => ListTile(
        leading: const Icon(IconlyLight.bag, color: Color(0xFF0F62FE), size: 20),
        title: Text(item['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text("${item['group'] ?? 'General'} · ${item['rate'] ?? 'Default'}", style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteMaterial(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // ================= 7. Custom Statuses Tab =================
  Widget _buildCustomStatusesTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Custom Statuses",
      subtitle: "Define template-specific workflow statuses.",
      actionLabel: "+ Add Status",
      onAction: () => _showAddSimpleItemDialog("Add Status", "Status Label", "Color (e.g. Green, Blue)", (label, color) => _controller.addCustomStatus(label, color ?? 'Blue')),
      isLoading: _controller.isLoadingCustomStatuses,
      items: _controller.customStatuses,
      itemBuilder: (item) => ListTile(
        leading: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(color: Color(0xFF0F62FE), shape: BoxShape.circle),
        ),
        title: Text(item['label']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteCustomStatus(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // ================= 8. Approvals Tab =================
  Widget _buildApprovalsTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Approvals",
      subtitle: "Configured approval stages and signers.",
      actionLabel: "+ Add Stage",
      onAction: () => _showAddSimpleItemDialog("Add Approval Stage", "Stage Name", "Description", (name, desc) => _controller.addApprovalStage(name, desc ?? '')),
      isLoading: _controller.isLoadingApprovals,
      items: _controller.approvals,
      itemBuilder: (item) => ListTile(
        leading: const Icon(IconlyLight.shield_done, color: Color(0xFF0F62FE), size: 20),
        title: Text(item['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: (item['description']?.toString() ?? '').isNotEmpty ? Text(item['description'], style: TextStyle(fontSize: 12, color: textSecondary)) : null,
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteApprovalStage(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // ================= 9. Folders Tab =================
  Widget _buildFoldersTab(bool isDark, Color cardColor, Color textColor, Color textSecondary, Color borderColor) {
    return _buildGenericSubTab(
      title: "Folders",
      subtitle: "Predefined document folders for projects using this template.",
      actionLabel: "+ Add Folder",
      onAction: () => _showAddSimpleItemDialog("Add Folder", "Folder Name", null, (name, _) => _controller.addFolder(name)),
      isLoading: _controller.isLoadingFolders,
      items: _controller.folders,
      itemBuilder: (item) => ListTile(
        leading: const Icon(IconlyLight.folder, color: Color(0xFF0F62FE), size: 20),
        title: Text(item['name']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        trailing: IconButton(
          icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
          onPressed: () => _controller.deleteFolder(item['id'] as int),
        ),
      ),
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      textSecondary: textSecondary,
      borderColor: borderColor,
    );
  }

  // Reusable Generic Sub-Tab Wrapper
  Widget _buildGenericSubTab({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isLoading,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor)),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onAction,
                    child: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(fontSize: 13, color: textSecondary)),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(IconlyLight.folder, size: 36, color: textSecondary),
                      const SizedBox(height: 8),
                      Text("No items configured yet.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 4),
                      Text("Tap '$actionLabel' above to add one.", style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: itemBuilder(item),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddSimpleItemDialog(
    String dialogTitle,
    String field1Label,
    String? field2Label,
    Function(String, String?) onSave,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final inputFill = isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF9FAFB);

    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(dialogTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field1Label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl1,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputFill,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              ),
            ),
            if (field2Label != null) ...[
              const SizedBox(height: 12),
              Text(field2Label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl2,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFill,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F62FE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final val1 = ctrl1.text.trim();
              if (val1.isEmpty) return;
              Navigator.pop(dialogContext);
              onSave(val1, ctrl2.text.trim().isEmpty ? null : ctrl2.text.trim());
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
