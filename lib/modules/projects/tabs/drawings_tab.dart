import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'drawing_pin_viewer_screen.dart';

class DrawingsTab extends StatefulWidget {
  final int? projectId;
  final List<dynamic>? rawBlocks;
  final List<dynamic>? drawings;
  final VoidCallback? onChanged;

  const DrawingsTab({
    super.key,
    this.projectId,
    this.rawBlocks,
    this.drawings,
    this.onChanged,
  });

  @override
  State<DrawingsTab> createState() => _DrawingsTabState();
}

class _DrawingsTabState extends State<DrawingsTab> {
  List<Map<String, dynamic>> _fetchedDrawings = [];
  String _selectedSiteFilter = 'All Blocks, All Levels';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLiveDrawings();
  }

  @override
  void didUpdateWidget(DrawingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawings != widget.drawings || oldWidget.projectId != widget.projectId) {
      _fetchLiveDrawings();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _extractName(dynamic val) {
    if (val == null) return '';
    if (val is Map) return (val['name'] ?? val['title'] ?? val['label'] ?? '').toString();
    return val.toString();
  }

  String _resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final base = ApiEndpoints.baseUrl.replaceAll('/api', '');
    return '$base${clean.startsWith('/') ? '' : '/'}$clean';
  }

  Future<void> _fetchLiveDrawings() async {
    if (widget.projectId == null) return;
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/?project_id=${widget.projectId}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List || decoded.containsKey('data'))) {
        final all = (decoded['data'] as List? ?? (decoded is List ? decoded : []))
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        if (mounted) {
          setState(() {
            _fetchedDrawings = all;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching live drawings: $e");
    }
  }

  List<Map<String, dynamic>> _getAllDrawings() {
    final Map<String, Map<String, dynamic>> byKey = {};

    // 1. From widget.drawings
    for (var d in (widget.drawings ?? [])) {
      if (d is Map) {
        final map = d.cast<String, dynamic>();
        final id = map['id']?.toString() ?? map['file_path']?.toString() ?? map['name']?.toString() ?? '';
        if (id.isNotEmpty) byKey[id] = map;
      }
    }

    // 2. From _fetchedDrawings (more up-to-date with pins & location details)
    for (var d in _fetchedDrawings) {
      final id = d['id']?.toString() ?? d['file_url']?.toString() ?? d['name']?.toString() ?? '';
      if (id.isNotEmpty) {
        byKey[id] = {...byKey[id] ?? {}, ...d};
      }
    }

    return byKey.values.toList();
  }

  List<Map<String, dynamic>> _findDrawingsForLevel(String blockName, String levelName, dynamic levelId) {
    final all = _getAllDrawings();
    final cleanBlock = blockName.trim().toLowerCase();
    final cleanLevel = levelName.trim().toLowerCase();

    return all.where((d) {
      final b = _extractName(d['block']).isNotEmpty ? _extractName(d['block']) : (d['block_name']?.toString() ?? '');
      final l = _extractName(d['level']).isNotEmpty ? _extractName(d['level']) : (d['level_name']?.toString() ?? '');
      final lId = d['level_id'] ?? (d['level'] is Map ? d['level']['id'] : null);

      if (levelId != null && lId != null && lId.toString() == levelId.toString()) {
        return true;
      }

      final bMatch = b.isEmpty || cleanBlock.isEmpty || b.trim().toLowerCase() == cleanBlock || cleanBlock.contains(b.trim().toLowerCase());
      final lMatch = l.trim().toLowerCase() == cleanLevel || (l.isNotEmpty && cleanLevel.contains(l.trim().toLowerCase()));

      return bMatch && lMatch;
    }).toList();
  }

  void _showRecycleBinDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchRecycledDrawings(),
          builder: (context, snapshot) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
            final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              content = Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(IconlyLight.delete, size: 48, color: textSecondary),
                    const SizedBox(height: 12),
                    Text("Recycle Bin is Empty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 4),
                    Text("No deleted drawings found for this project.", style: TextStyle(color: textSecondary, fontSize: 13)),
                  ],
                ),
              );
            } else {
              final list = snapshot.data!;
              content = ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final name = item['name']?.toString() ?? item['file_name']?.toString() ?? 'Drawing #${item['id']}';
                    final block = item['block_name']?.toString() ?? (item['block'] is Map ? item['block']['name'] : '') ?? '';
                    final level = item['level_name']?.toString() ?? (item['level'] is Map ? item['level']['name'] : '') ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(IconlyLight.image, color: Colors.redAccent, size: 20),
                      ),
                      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      subtitle: Text(
                        "$block ${level.isNotEmpty ? '· $level' : ''}",
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore, color: Color(0xFF0D6EFD), size: 20),
                            tooltip: "Restore Drawing",
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              await _restoreDrawing(item['id']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                            tooltip: "Delete Permanently",
                            onPressed: () async {
                              Navigator.pop(dialogCtx);
                              await _permanentlyDeleteDrawing(item['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }

            return AlertDialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(IconlyLight.delete, size: 20, color: Color(0xFF0D6EFD)),
                  const SizedBox(width: 8),
                  Text("Drawings Recycle Bin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                ],
              ),
              content: content,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecycledDrawings() async {
    if (widget.projectId == null) return [];
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/recycle-bin/?project_id=${widget.projectId}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List)) {
        final list = (decoded['data'] as List? ?? (decoded is List ? decoded : []))
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _restoreDrawing(dynamic drawingId) async {
    if (drawingId == null) return;
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/$drawingId/restore/';
      final response = await ApiClient.post(url, body: {});
      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onChanged?.call();
        _fetchLiveDrawings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Drawing restored successfully."), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restore failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteDrawing(dynamic drawingId) async {
    if (drawingId == null) return;
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/$drawingId/permanent-delete/';
      final response = await ApiClient.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        widget.onChanged?.call();
        _fetchLiveDrawings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Drawing deleted permanently."), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> blocks =
        (widget.rawBlocks ?? []).whereType<Map<String, dynamic>>().toList();
    final allDrawings = _getAllDrawings();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    // Filter options for Site dropdown
    final List<String> siteFilterOptions = ['All Blocks, All Levels'];
    for (var b in blocks) {
      final bName = b['name']?.toString() ?? 'Block';
      siteFilterOptions.add(bName);
      final levels = b['levels'] as List<dynamic>? ?? [];
      for (var l in levels) {
        final lName = l['name']?.toString() ?? 'Level';
        siteFilterOptions.add('$bName / $lName');
      }
    }

    return Column(
      children: [
        // Web Parity Toolbar: Filters, Recycle Bin, and Action Buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Site Filter Dropdown + Refresh + Recycle Bin
              Row(
                children: [
                  // Site Filter Dropdown
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: siteFilterOptions.contains(_selectedSiteFilter) ? _selectedSiteFilter : 'All Blocks, All Levels',
                          isExpanded: true,
                          dropdownColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontFamily: 'Inter',
                          ),
                          items: siteFilterOptions.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt,
                              child: Text(opt, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSiteFilter = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Refresh Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: "Refresh Drawings",
                    onPressed: () {
                      _fetchLiveDrawings();
                      widget.onChanged?.call();
                    },
                    icon: Icon(Icons.refresh, size: 20, color: textColor),
                  ),
                  const SizedBox(width: 8),

                  // Recycle Bin Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showRecycleBinDialog,
                    icon: const Icon(IconlyLight.delete, size: 16),
                    label: const Text(
                      "Recycle Bin",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Add Block & Levels
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () => _showAddBlockDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    "Add Block & Levels",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Drawings Gallery & Blocks List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchLiveDrawings();
              widget.onChanged?.call();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. ACTIVE DRAWINGS BLUEPRINT CARDS SECTION
                if (allDrawings.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(IconlyLight.image, size: 16, color: Color(0xFF0D6EFD)),
                      const SizedBox(width: 8),
                      Text(
                        "Drawing Blueprints (${allDrawings.length})",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...allDrawings.map((drawing) {
                    final dName = drawing['name']?.toString() ??
                        drawing['file_name']?.toString() ??
                        drawing['title']?.toString() ??
                        'Drawing';
                    final bName = _extractName(drawing['block']).isNotEmpty
                        ? _extractName(drawing['block'])
                        : (drawing['block_name']?.toString() ?? 'Block 1');
                    final lName = _extractName(drawing['level']).isNotEmpty
                        ? _extractName(drawing['level'])
                        : (drawing['level_name']?.toString() ?? 'l2');
                    final rawPins = drawing['locations'] ?? drawing['pins'] ?? drawing['drawing_locations'] ?? [];
                    final pinCount = (rawPins is List) ? rawPins.length : (int.tryParse(drawing['pin_count']?.toString() ?? '0') ?? 0);
                    final fileUrl = _resolveUrl(drawing['file_url']?.toString() ?? drawing['file_path']?.toString() ?? drawing['file']?.toString());

                    // Check site filter
                    if (_selectedSiteFilter != 'All Blocks, All Levels') {
                      if (_selectedSiteFilter.contains('/')) {
                        final parts = _selectedSiteFilter.split('/');
                        final filterB = parts[0].trim().toLowerCase();
                        final filterL = parts[1].trim().toLowerCase();
                        if (bName.toLowerCase().trim() != filterB || lName.toLowerCase().trim() != filterL) {
                          return const SizedBox.shrink();
                        }
                      } else {
                        if (bName.toLowerCase().trim() != _selectedSiteFilter.trim().toLowerCase()) {
                          return const SizedBox.shrink();
                        }
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (widget.projectId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DrawingPinViewerScreen(
                                    projectId: widget.projectId!,
                                    blockName: bName,
                                    levelName: lName,
                                    initialDrawing: drawing,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              children: [
                                // Thumbnail with Pin Count Badge
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: fileUrl.isNotEmpty
                                          ? Image.network(
                                              fileUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(
                                                child: Icon(IconlyLight.image, size: 28, color: Colors.grey),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(IconlyLight.image, size: 28, color: Colors.grey),
                                            ),
                                    ),
                                    if (pinCount > 0)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF0D6EFD),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "$pinCount",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Drawing Name & Block/Level Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: textColor,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "$bName / $lName",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textSecondary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(IconlyLight.location, size: 13, color: const Color(0xFF0D6EFD)),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$pinCount pin${pinCount != 1 ? 's' : ''}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF0D6EFD),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Arrow / Pins Button
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0D6EFD),
                                    side: const BorderSide(color: Color(0xFF0D6EFD)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    if (widget.projectId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DrawingPinViewerScreen(
                                            projectId: widget.projectId!,
                                            blockName: bName,
                                            levelName: lName,
                                            initialDrawing: drawing,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Pins", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Divider(color: borderColor),
                  const SizedBox(height: 16),
                ],

                // 2. BLOCKS & LEVELS MANAGEMENT SECTION
                Row(
                  children: [
                    const Icon(IconlyLight.category, size: 16, color: Color(0xFF0D6EFD)),
                    const SizedBox(width: 8),
                    Text(
                      "Blocks & Levels (${blocks.length})",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (blocks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyLight.category, size: 48, color: textSecondary),
                          const SizedBox(height: 12),
                          Text("No Blocks or Levels configured yet.",
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text("Tap '+ Add Block & Levels' above to set up site structure.",
                              style: TextStyle(color: textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ...blocks.map((block) {
                    final blockName = block['name']?.toString() ?? 'Unknown Block';
                    final levels = block['levels'] as List<dynamic>? ?? [];
                    return _buildBlockCard(context, blockName, levels, isDark, cardColor, borderColor, textColor, textSecondary);
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    String blockName,
    List<dynamic> levels,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: textColor,
          collapsedIconColor: textColor,
          title: Text(
            blockName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(IconlyLight.work, color: Color(0xFF0D6EFD), size: 20),
          ),
          children: levels.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("No levels found for this block", style: TextStyle(color: textSecondary)),
                  )
                ]
              : levels.map((l) {
                  final levelName = l['name']?.toString() ?? 'Level';
                  final levelId = l['id'];
                  final matchingDrawings = _findDrawingsForLevel(blockName, levelName, levelId);
                  final hasDrawings = matchingDrawings.isNotEmpty;
                  final drawingCount = matchingDrawings.length;
                  final firstDrawing = hasDrawings ? matchingDrawings.first : null;
                  final rawUrl = firstDrawing != null
                      ? (firstDrawing['file_url'] ?? firstDrawing['file_path'] ?? firstDrawing['file'] ?? firstDrawing['url'])?.toString()
                      : null;
                  final resolvedFileUrl = _resolveUrl(rawUrl);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(IconlyLight.category, color: textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              levelName,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                            ),
                            if (hasDrawings) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$drawingCount drawing${drawingCount > 1 ? 's' : ''}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Action buttons row
                        Row(
                          children: [
                            // Upload Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                foregroundColor: textColor,
                              ),
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg'],
                                );
                                final pickedFile = result?.files.first;
                                if (pickedFile == null || pickedFile.path == null || widget.projectId == null) return;
                                try {
                                  final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
                                  final response = await ApiClient.postMultipart(
                                    url,
                                    filePath: pickedFile.path!,
                                    fields: {
                                      "module": "drawings",
                                      "level_id": levelId?.toString() ?? '',
                                      "name": pickedFile.name,
                                    },
                                  );
                                  if (response.statusCode == 200 || response.statusCode == 201) {
                                    widget.onChanged?.call();
                                    _fetchLiveDrawings();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text("Uploaded '${pickedFile.name}' to $blockName -> $levelName."),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    final decoded = jsonDecode(response.body);
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(decoded['message']?.toString() ?? 'Upload failed.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              },
                              icon: const Icon(IconlyLight.upload, size: 16),
                              label: const Text("Upload", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            const SizedBox(width: 8),

                            // View File Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {
                                if (!hasDrawings || resolvedFileUrl.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("No drawing files uploaded for this level yet.")),
                                  );
                                  return;
                                }
                                launchUrl(Uri.parse(resolvedFileUrl), mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(IconlyLight.show, size: 16),
                              label: const Text("View File", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 8),

                            // Pins Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.deepPurple),
                                foregroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: widget.projectId == null
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DrawingPinViewerScreen(
                                            projectId: widget.projectId!,
                                            blockName: blockName,
                                            levelName: levelName,
                                            initialDrawing: firstDrawing,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(IconlyLight.location, size: 16),
                              label: const Text("Pins", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
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
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Add Block & Levels",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            ),
          ),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                "Cancel",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final blockName = blockController.text.trim();
                final levels = levelsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (blockName.isEmpty || levels.isEmpty || widget.projectId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all fields")),
                  );
                  return;
                }

                try {
                  final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
                  final response = await ApiClient.post(url, body: {
                    "module": "blocks",
                    "block_name": blockName,
                    "level_names": levels,
                  });
                  final decoded = jsonDecode(response.body);
                  if (!context.mounted) return;
                  Navigator.pop(dialogCtx);
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    widget.onChanged?.call();
                    _fetchLiveDrawings();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(decoded['message']?.toString() ?? 'Failed to create block.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create block: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text("Create Block", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
