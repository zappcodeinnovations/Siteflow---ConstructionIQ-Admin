import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class DrawingsTab extends StatelessWidget {
  final List<dynamic>? rawBlocks;
  final List<dynamic>? drawings;

  const DrawingsTab({Key? key, this.rawBlocks, this.drawings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> blocks =
        (rawBlocks ?? []).whereType<Map<String, dynamic>>().toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.corporateBlue : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                children: [
                  _buildFilterDropdown(
                      context,
                      "Select Block",
                      blocks
                          .map((b) => b['name']?.toString() ?? 'Unnamed')
                          .toList()),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  _showAddBlockDialog(context);
                },
                icon: const Icon(IconlyLight.plus, size: 16),
                label: const Text("Add Block & Levels",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: blocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.category,
                          size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No Drawings/Blocks available",
                          style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: blocks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final block = blocks[index];
                    final levels = block['levels'] as List<dynamic>? ?? [];
                    return _buildBlockCard(
                        context, block['name']?.toString() ?? 'Unknown Block', levels);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(BuildContext context, String label, List<dynamic> options) {
    if (options.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ensure unique values to prevent DropdownButton assertion failures
    final uniqueOptions = options.map((e) => e.toString()).toSet().toList();

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
          value: null,
          hint: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
          items: uniqueOptions
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87))))
              .toList(),
          onChanged: (val) {},
          icon: Icon(IconlyLight.arrow_down_2,
              color: isDark ? Colors.white70 : Colors.black54, size: 18),
        ),
      ),
    );
  }

  Widget _buildBlockCard(
      BuildContext context, String blockName, List<dynamic> levels) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: isDark ? Colors.white : Colors.black54,
          collapsedIconColor: isDark ? Colors.white : Colors.black54,
          title: Text(blockName,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(IconlyLight.work, color: isDark ? Colors.white : const Color(0xFF0D6EFD), size: 20),
          ),
          children: levels.isEmpty
              ? [
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("No levels found",
                          style: TextStyle(color: textSecondary)))
                ]
              : levels.map((l) {
                  final levelName = l['name']?.toString() ?? 'Level';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border:
                          Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(IconlyLight.category,
                                color: textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text(levelName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                              ),
                              onPressed: () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg'],
                                );
                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Uploading '${result.files.first.name}' to $blockName -> $levelName...")));
                                }
                              },
                              icon: Icon(IconlyLight.upload, size: 16, color: isDark ? Colors.white : Colors.black87),
                              label: const Text("Upload",
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                final List<dynamic> blockDrawings = drawings ?? [];
                                final matches = blockDrawings.where((d) {
                                  final dMap = d as Map<String, dynamic>? ?? {};
                                  final dBlock = dMap['block']?.toString() ?? '';
                                  final dLevel = dMap['level']?.toString() ?? '';
                                  return dBlock == blockName && dLevel == levelName;
                                }).toList();

                                if (matches.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "No drawing files uploaded for this level yet.")));
                                  return;
                                }

                                final firstDrawing = matches.first as Map<String, dynamic>;
                                final fileUrl = firstDrawing['file_path']?.toString() ?? '';

                                if (fileUrl.isNotEmpty) {
                                  launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Invalid drawing file URL")));
                                }
                              },
                              icon: const Icon(IconlyLight.show, size: 16),
                              label: const Text("View File",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

  void _showAddBlockDialog(BuildContext context) {
    final blockController = TextEditingController();
    final levelsController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("Add Block & Levels",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: blockController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Block Name",
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                    hintText: "e.g., Block A",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: levelsController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: "Level Names",
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                    hintText: "Comma separated (e.g., Level 1, Level 2)",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel",
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final blockName = blockController.text.trim();
                  final levels = levelsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  if (blockName.isEmpty || levels.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Simulating API POST for Block '$blockName' with ${levels.length} levels...")));
                  Navigator.pop(context);
                },
                child: const Text("Create Block",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
  }
}
