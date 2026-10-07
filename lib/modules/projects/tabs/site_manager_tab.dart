import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/site_structure_models.dart';

class SiteManagerTab extends StatelessWidget {
  final List<dynamic>? rawBlocks;
  const SiteManagerTab({Key? key, this.rawBlocks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    final blocks = SiteBlockModel.listFromRaw(rawBlocks);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blocks.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Text("No site structure set up yet.",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Blocks, levels and zones are managed from the web admin panel.",
                      textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
                ],
              ),
            )
          else
            ...blocks.map((block) => _buildBlockCard(block, cardColor, borderColor, textColor, textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBlockCard(SiteBlockModel block, Color cardColor, Color borderColor, Color textColor, Color textSecondary) {
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
          leading: Icon(IconlyBold.category, color: textColor, size: 20),
          title: Text(block.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          subtitle: Text("${block.levels.length} level${block.levels.length == 1 ? '' : 's'}",
              style: TextStyle(fontSize: 12, color: textSecondary)),
          children: block.levels.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("No levels added.", style: TextStyle(color: textSecondary, fontSize: 13)),
                    ),
                  ),
                ]
              : block.levels
                  .map((level) => _buildLevelRow(level, borderColor, textColor, textSecondary))
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildLevelRow(SiteLevelModel level, Color borderColor, Color textColor, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(IconlyLight.folder, size: 16, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(level.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                ),
                if (level.drawingUrl.isNotEmpty || level.drawingCount > 0) ...[
                  Icon(IconlyLight.image, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text("${level.drawingCount > 0 ? level.drawingCount : 1} drawing${(level.drawingCount > 1) ? 's' : ''}",
                      style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ],
            ),
            if (level.zones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: level.zones.map((zone) {
                  final label = zone.zoneCore.isNotEmpty ? "${zone.name} (${zone.zoneCore})" : zone.name;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label, style: TextStyle(fontSize: 11, color: textColor)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
