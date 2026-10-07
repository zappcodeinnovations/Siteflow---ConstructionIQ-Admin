import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/project_material_model.dart';
import '../project_materials_controller.dart';

class MaterialsTab extends StatefulWidget {
  final int projectId;
  const MaterialsTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<MaterialsTab> {
  late final ProjectMaterialsController _controller = ProjectMaterialsController(widget.projectId);

  @override
  void initState() {
    super.initState();
    _controller.fetchMaterials();
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
          onRefresh: _controller.fetchMaterials,
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
                        TextButton(onPressed: _controller.fetchMaterials, child: const Text("Retry")),
                      ],
                    ),
                  )
                else if (_controller.materials.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Text("No materials assigned to this project yet.",
                            style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Materials and rate sets are managed from the web admin panel's Library.",
                            textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                else
                  ..._controller.materials.map((m) => _buildMaterialCard(m, cardColor, borderColor, textColor, textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialCard(ProjectMaterialModel material, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(IconlyBold.bag, color: textColor, size: 20),
          title: Text(material.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          subtitle: Text(
            [
              if (material.materialGroup.isNotEmpty) material.materialGroup,
              material.inputTypeLabel,
            ].where((s) => s.isNotEmpty).join(' · '),
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (material.manufacturer.isNotEmpty || material.productCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        [
                          if (material.manufacturer.isNotEmpty) material.manufacturer,
                          if (material.productCode.isNotEmpty) "Code: ${material.productCode}",
                        ].join('  ·  '),
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ),
                  if (material.rateSets.isEmpty)
                    Text("No rate sets configured.", style: TextStyle(fontSize: 13, color: textSecondary))
                  else
                    ...material.rateSets.map((rs) => _buildRateSetRow(rs, borderColor, textColor, textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSetRow(MaterialRateSetModel rateSet, Color borderColor, Color textColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("${rateSet.categoryLabel} · ${rateSet.name}",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
              ),
              if (rateSet.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF16A34A).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text("Default", style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (rateSet.minimumMeasure != null) ...[
            const SizedBox(height: 4),
            Text("Minimum measure: ${rateSet.minimumMeasure}", style: TextStyle(fontSize: 11, color: textSecondary)),
          ],
          if (rateSet.tiers.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...rateSet.tiers.map((tier) => Text(
                  "${tier.tierTypeLabel}${tier.thresholdValue != null ? ' ${tier.thresholdValue}' : ''}: flat ${tier.flatAmount}, per unit ${tier.perUnitAmount}",
                  style: TextStyle(fontSize: 11, color: textSecondary),
                )),
          ],
        ],
      ),
    );
  }
}
