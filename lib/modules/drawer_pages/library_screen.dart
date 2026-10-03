import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/library_form_model.dart';
import '../../models/library_template_model.dart';
import '../../models/project_material_model.dart';
import 'library_controller.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  final LibraryController _controller = LibraryController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.fetchForms();
    _controller.fetchMaterials();
    _controller.fetchTemplates();
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
    final background = isDark ? AppTheme.corporateBlue : const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Forms"),
            Tab(text: "Materials"),
            Tab(text: "Templates"),
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
                ],
              );
            },
          ),
        ],
      ),
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
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
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
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

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

  Widget _buildMaterialsTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    if (_controller.isLoadingMaterials) return const Center(child: CircularProgressIndicator());
    if (_controller.materialsError != null) return _errorState(_controller.materialsError!, _controller.fetchMaterials);
    if (_controller.materials.isEmpty) {
      return _emptyState(isDark, "No materials in the catalog yet.", "Materials and rate sets are managed from the web admin panel's Library.");
    }
    return RefreshIndicator(
      onRefresh: _controller.fetchMaterials,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.materials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final LibraryMaterialModel material = _controller.materials[index];
          return Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: ExpansionTile(
                leading: Icon(IconlyBold.bag, color: textColor, size: 18),
                title: Text(material.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                subtitle: Text(
                  [if (material.materialGroup.isNotEmpty) material.materialGroup, material.inputTypeLabel]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(fontSize: 12, color: textSecondary),
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
          );
        },
      ),
    );
  }

  Widget _buildTemplatesTab(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

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
