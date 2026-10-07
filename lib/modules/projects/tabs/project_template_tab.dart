import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_template_detail_model.dart';
import '../project_template_controller.dart';

class ProjectTemplateTab extends StatefulWidget {
  final int projectId;
  const ProjectTemplateTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ProjectTemplateTab> createState() => _ProjectTemplateTabState();
}

class _ProjectTemplateTabState extends State<ProjectTemplateTab> {
  late final ProjectTemplateController _controller = ProjectTemplateController(widget.projectId);

  @override
  void initState() {
    super.initState();
    _controller.fetchTemplate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.fetchTemplate,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(_controller.error!, style: TextStyle(color: textSecondary)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _controller.fetchTemplate, child: const Text("Retry")),
                      ],
                    ),
                  )
                else if (_controller.hasNoTemplate || _controller.template == null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text("No template assigned to this project.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Templates are assigned from the web admin panel's Project Setup.",
                            textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  _buildTemplateContent(_controller.template!, cardColor, borderColor, textColor, textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateContent(ProjectTemplateDetailModel template, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(template.templateName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(template.templateStatus, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(template.description, style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
              const SizedBox(height: 4),
              Text("${template.fields.length} field${template.fields.length == 1 ? '' : 's'}",
                  style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...template.fields.map((field) => _buildFieldCard(field, cardColor, borderColor, textColor, textSecondary)),
      ],
    );
  }

  Widget _buildFieldCard(TemplateFieldModel field, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconlyLight.edit, size: 15, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(field.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
              ),
              if (field.required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFDC2626).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text("Required", style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text("${field.fieldType}${field.scope.isNotEmpty ? ' · ${field.scope}' : ''}",
              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500)),
          if (field.helpText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(field.helpText, style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
          if (field.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: field.options.map((opt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(opt, style: TextStyle(fontSize: 11, color: textColor)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
