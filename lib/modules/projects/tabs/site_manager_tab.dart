import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/site_structure_models.dart';
import 'drawing_pin_viewer_screen.dart';

class SiteManagerTab extends StatefulWidget {
  final int? projectId;
  final List<dynamic>? rawBlocks;
  final List<dynamic>? drawings;
  final VoidCallback? onChanged;

  const SiteManagerTab({
    super.key,
    this.projectId,
    this.rawBlocks,
    this.drawings,
    this.onChanged,
  });

  @override
  State<SiteManagerTab> createState() => _SiteManagerTabState();
}

class _SiteManagerTabState extends State<SiteManagerTab> {
  List<Map<String, dynamic>> _fetchedDrawings = [];

  // Site Filter Hierarchical State
  bool _isAllSelected = true;
  final Set<String> _selectedBlocks = {};
  final Set<String> _selectedLevels = {}; // Stored as "$blockName/$levelName"

  // Search State
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Import Drawings State
  String? _selectedImportLevelKey;
  PlatformFile? _selectedDrawingFile;
  bool _isUploadingDrawing = false;

  // CSV Import State
  bool _isImportingCsv = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _importDrawingsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initAllSelections();
    _fetchLiveDrawings();
  }

  @override
  void didUpdateWidget(SiteManagerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawBlocks != widget.rawBlocks) {
      _initAllSelections();
    }
    if (oldWidget.drawings != widget.drawings || oldWidget.projectId != widget.projectId) {
      _fetchLiveDrawings();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initAllSelections() {
    final blocks = SiteBlockModel.listFromRaw(widget.rawBlocks);
    _selectedBlocks.clear();
    _selectedLevels.clear();
    for (var b in blocks) {
      _selectedBlocks.add(b.name);
      for (var l in b.levels) {
        _selectedLevels.add('${b.name}/${l.name}');
      }
    }
    _isAllSelected = true;
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

  void _openDrawingFile(String? url) {
    final resolved = _resolveUrl(url);
    if (resolved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No drawing file uploaded for this level yet.")),
      );
      return;
    }
    launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
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
      debugPrint("Error fetching live drawings in SiteManagerTab: $e");
    }
  }

  List<Map<String, dynamic>> _getAllDrawings() {
    final Map<String, Map<String, dynamic>> byKey = {};
    for (var d in (widget.drawings ?? [])) {
      if (d is Map) {
        final map = d.cast<String, dynamic>();
        final id = map['id']?.toString() ?? map['file_path']?.toString() ?? map['name']?.toString() ?? '';
        if (id.isNotEmpty) byKey[id] = map;
      }
    }
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

  String get _activeSiteFilterSummary {
    if (_isAllSelected) {
      return "Site: All Blocks, All Levels";
    }
    if (_selectedLevels.isEmpty && _selectedBlocks.isEmpty) {
      return "Site: None Selected";
    }
    if (_selectedLevels.length == 1) {
      final parts = _selectedLevels.first.split('/');
      if (parts.length >= 2) {
        return "Site: ${parts[0]} / ${parts[1]}";
      }
      return "Site: ${_selectedLevels.first}";
    }
    if (_selectedBlocks.length == 1 && _selectedLevels.length > 1) {
      return "Site: ${_selectedBlocks.first} (${_selectedLevels.length} Levels)";
    }
    return "Site: ${_selectedBlocks.length} Blocks, ${_selectedLevels.length} Levels";
  }

  void _showSiteFilterPopover(BuildContext context) {
    final blocks = SiteBlockModel.listFromRaw(widget.rawBlocks);

    // Local temporary state in popover
    bool tempSelectAll = _isAllSelected;
    final Set<String> tempBlocks = Set.from(_selectedBlocks);
    final Set<String> tempLevels = Set.from(_selectedLevels);

    showDialog(
      context: context,
      builder: (popoverCtx) {
        return StatefulBuilder(
          builder: (context, setPopoverState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
            final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

            void toggleSelectAll(bool? val) {
              final checked = val ?? false;
              setPopoverState(() {
                tempSelectAll = checked;
                tempBlocks.clear();
                tempLevels.clear();
                if (checked) {
                  for (var b in blocks) {
                    tempBlocks.add(b.name);
                    for (var l in b.levels) {
                      tempLevels.add('${b.name}/${l.name}');
                    }
                  }
                }
              });
            }

            void toggleBlock(String bName, List<SiteLevelModel> levels, bool? val) {
              final checked = val ?? false;
              setPopoverState(() {
                if (checked) {
                  tempBlocks.add(bName);
                  for (var l in levels) {
                    tempLevels.add('$bName/${l.name}');
                  }
                } else {
                  tempBlocks.remove(bName);
                  for (var l in levels) {
                    tempLevels.remove('$bName/${l.name}');
                  }
                }

                int totalLevelsCount = 0;
                for (var b in blocks) {
                  totalLevelsCount += b.levels.length;
                }
                tempSelectAll = (totalLevelsCount > 0 && tempLevels.length == totalLevelsCount);
              });
            }

            void toggleLevel(String bName, String lName, List<SiteLevelModel> allBlockLevels, bool? val) {
              final checked = val ?? false;
              final key = '$bName/$lName';
              setPopoverState(() {
                if (checked) {
                  tempLevels.add(key);
                } else {
                  tempLevels.remove(key);
                }

                final allLevelKeys = allBlockLevels.map((l) => '$bName/${l.name}').toSet();
                if (allLevelKeys.isNotEmpty && tempLevels.containsAll(allLevelKeys)) {
                  tempBlocks.add(bName);
                } else {
                  tempBlocks.remove(bName);
                }

                int totalLevelsCount = 0;
                for (var b in blocks) {
                  totalLevelsCount += b.levels.length;
                }
                tempSelectAll = (totalLevelsCount > 0 && tempLevels.length == totalLevelsCount);
              });
            }

            return Dialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Popover Header: Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Site Filter",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: textSecondary,
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => Navigator.pop(popoverCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 10),

                    // Hierarchical Checkbox Tree
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Master "Select All" Checkbox
                            CheckboxListTile(
                              value: tempSelectAll,
                              activeColor: const Color(0xFF0D6EFD),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                "Select All",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              onChanged: toggleSelectAll,
                            ),
                            const SizedBox(height: 4),
                            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                            const SizedBox(height: 4),

                            if (blocks.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  "No blocks or levels available.",
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                              )
                            else
                              ...blocks.map((block) {
                                final isBlockChecked = tempBlocks.contains(block.name);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Parent Block Checkbox
                                    CheckboxListTile(
                                      value: isBlockChecked,
                                      activeColor: const Color(0xFF0D6EFD),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      title: Text(
                                        block.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: textColor,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      onChanged: (val) => toggleBlock(block.name, block.levels, val),
                                    ),

                                    // Indented Child Level Checkboxes
                                    ...block.levels.map((lvl) {
                                      final levelKey = '${block.name}/${lvl.name}';
                                      final isLevelChecked = tempLevels.contains(levelKey);

                                      return Padding(
                                        padding: const EdgeInsets.only(left: 28.0),
                                        child: CheckboxListTile(
                                          value: isLevelChecked,
                                          activeColor: const Color(0xFF0D6EFD),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          controlAffinity: ListTileControlAffinity.leading,
                                          title: Text(
                                            lvl.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: textColor,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          onChanged: (val) => toggleLevel(block.name, lvl.name, block.levels, val),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 4),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor),
                    const SizedBox(height: 12),

                    // Action Footer: Clear & Apply Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setPopoverState(() {
                              tempSelectAll = false;
                              tempBlocks.clear();
                              tempLevels.clear();
                            });
                          },
                          child: Text(
                            "Clear",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              _isAllSelected = tempSelectAll;
                              _selectedBlocks.clear();
                              _selectedBlocks.addAll(tempBlocks);
                              _selectedLevels.clear();
                              _selectedLevels.addAll(tempLevels);
                            });
                            Navigator.pop(popoverCtx);
                          },
                          child: const Text(
                            "Apply",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Action: Add Block Dialog
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
            "Add Block",
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
                  labelText: "Block Name *",
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  hintText: "e.g., Block 2",
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
                  hintText: "Comma separated (e.g., Ground, First)",
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

                if (blockName.isEmpty || widget.projectId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Block name is required.")),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Block '$blockName' created successfully."), backgroundColor: Colors.green),
                    );
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

  // Action: Add Level Dialog
  void _showAddLevelDialog(BuildContext context, {SiteBlockModel? preselectedBlock}) {
    final blocks = SiteBlockModel.listFromRaw(widget.rawBlocks);
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a Block first before adding levels.")),
      );
      return;
    }

    SiteBlockModel selectedBlock = preselectedBlock ?? blocks.first;
    final levelController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Add Level",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<SiteBlockModel>(
                    initialValue: selectedBlock,
                    decoration: InputDecoration(
                      labelText: "Target Block *",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: blocks.map((b) {
                      return DropdownMenuItem<SiteBlockModel>(
                        value: b,
                        child: Text(b.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedBlock = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: levelController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Level Name *",
                      hintText: "e.g., Level 3",
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
                    final levelName = levelController.text.trim();
                    if (levelName.isEmpty || widget.projectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Level name is required.")),
                      );
                      return;
                    }

                    try {
                      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
                      final response = await ApiClient.post(url, body: {
                        "module": "levels",
                        "block_id": selectedBlock.id,
                        "block_name": selectedBlock.name,
                        "level_name": levelName,
                      });
                      final decoded = jsonDecode(response.body);
                      if (!context.mounted) return;
                      Navigator.pop(dialogCtx);
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        widget.onChanged?.call();
                        _fetchLiveDrawings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Level '$levelName' added to ${selectedBlock.name}."), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(decoded['message']?.toString() ?? 'Failed to add level.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add level: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text("Add Level", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Action: Add Zone Dialog
  void _showAddZoneDialog(BuildContext context, {SiteBlockModel? preselectedBlock, SiteLevelModel? preselectedLevel}) {
    final blocks = SiteBlockModel.listFromRaw(widget.rawBlocks);
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a Block and Level first.")),
      );
      return;
    }

    SiteBlockModel selectedBlock = preselectedBlock ?? blocks.first;
    SiteLevelModel? selectedLevel = preselectedLevel ?? (selectedBlock.levels.isNotEmpty ? selectedBlock.levels.first : null);
    final zoneNameController = TextEditingController();
    final zoneCoreController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Add Zone",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<SiteBlockModel>(
                    initialValue: selectedBlock,
                    decoration: InputDecoration(
                      labelText: "Block *",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: blocks.map((b) {
                      return DropdownMenuItem<SiteBlockModel>(
                        value: b,
                        child: Text(b.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedBlock = val;
                          selectedLevel = val.levels.isNotEmpty ? val.levels.first : null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  if (selectedBlock.levels.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text("Selected block has no levels.", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    )
                  else
                    DropdownButtonFormField<SiteLevelModel>(
                      initialValue: selectedLevel,
                      decoration: InputDecoration(
                        labelText: "Level *",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      items: selectedBlock.levels.map((l) {
                        return DropdownMenuItem<SiteLevelModel>(
                          value: l,
                          child: Text(l.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedLevel = val;
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: zoneNameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Zone Name *",
                      hintText: "e.g., Zone A",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: zoneCoreController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Zone Core (Optional)",
                      hintText: "e.g., Core 1",
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
                    final zoneName = zoneNameController.text.trim();
                    final zoneCore = zoneCoreController.text.trim();
                    if (zoneName.isEmpty || selectedLevel == null || widget.projectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Zone name and level are required.")),
                      );
                      return;
                    }

                    try {
                      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
                      final response = await ApiClient.post(url, body: {
                        "module": "zones",
                        "level_id": selectedLevel!.id,
                        "zone_name": zoneName,
                        "zone_core": zoneCore,
                      });
                      final decoded = jsonDecode(response.body);
                      if (!context.mounted) return;
                      Navigator.pop(dialogCtx);
                      if (response.statusCode == 200 || response.statusCode == 201) {
                        widget.onChanged?.call();
                        _fetchLiveDrawings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Zone '$zoneName' added to ${selectedLevel!.name}."), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(decoded['message']?.toString() ?? 'Failed to add zone.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add zone: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text("Add Zone", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Action: Add Menu Popup
  void _showAddActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Add Site Structure Element",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0D6EFD).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(IconlyLight.category, color: Color(0xFF0D6EFD), size: 20),
                  ),
                  title: const Text("Add Block", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("Create a new building block or section"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddBlockDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(IconlyLight.folder, color: Colors.green, size: 20),
                  ),
                  title: const Text("Add Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("Add a floor or level under an existing block"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddLevelDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(IconlyLight.location, color: Colors.purple, size: 20),
                  ),
                  title: const Text("Add Zone", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("Add an apartment, room, or sub-zone to a level"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddZoneDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Action: Reorder Bottom Sheet
  void _showReorderBottomSheet(BuildContext context) {
    final blocks = SiteBlockModel.listFromRaw(widget.rawBlocks);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        List<SiteBlockModel> editableBlocks = List.from(blocks);

        return StatefulBuilder(
          builder: (context, setReorderState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Reorder Blocks & Levels",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Drag and drop handles to reorder site hierarchy.",
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ReorderableListView(
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        setReorderState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = editableBlocks.removeAt(oldIndex);
                          editableBlocks.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int index = 0; index < editableBlocks.length; index++)
                          Container(
                            key: ValueKey(editableBlocks[index].id),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                            ),
                            child: ListTile(
                              leading: const Icon(IconlyLight.category, color: Color(0xFF0D6EFD)),
                              title: Text(
                                editableBlocks[index].name,
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                              ),
                              subtitle: Text("${editableBlocks[index].levels.length} levels"),
                              trailing: const Icon(Icons.drag_handle),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hierarchy order updated successfully."), backgroundColor: Colors.green),
                      );
                    },
                    child: const Text("Save Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Action: Upload Drawing for Level
  Future<void> _uploadDrawingForSelectedLevel() async {
    if (_selectedDrawingFile == null || _selectedDrawingFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a drawing file to upload.")),
      );
      return;
    }

    if (_selectedImportLevelKey == null || widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a target level.")),
      );
      return;
    }

    final levelId = _selectedImportLevelKey;

    setState(() {
      _isUploadingDrawing = true;
    });

    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
      final response = await ApiClient.postMultipart(
        url,
        filePath: _selectedDrawingFile!.path!,
        fields: {
          "module": "drawings",
          "level_id": levelId?.toString() ?? '',
          "name": _selectedDrawingFile!.name,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onChanged?.call();
        await _fetchLiveDrawings();
        if (mounted) {
          setState(() {
            _selectedDrawingFile = null;
            _isUploadingDrawing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Drawing uploaded successfully!"), backgroundColor: Colors.green),
          );
        }
      } else {
        final decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isUploadingDrawing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decoded['message']?.toString() ?? 'Upload failed.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingDrawing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Action: Download CSV Template
  Future<void> _downloadCsvTemplate() async {
    const csvContent = "Block,Level,Zone,Zone Core\n"
        "Block 1,l1,Zone A,Core 1\n"
        "Block 1,l2,Zone B,Core 2\n"
        "Block 2,Ground,Reception,\n"
        "Block 2,First Floor,Unit 101,North\n";

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/locations_template.csv');
      await file.writeAsString(csvContent);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Site Locations CSV Template',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to export template: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Action: Import CSV File
  Future<void> _importCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    final picked = result?.files.first;
    if (picked == null || picked.path == null || widget.projectId == null) return;

    setState(() {
      _isImportingCsv = true;
    });

    try {
      final file = File(picked.path!);
      final content = await file.readAsString();
      final lines = content.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();

      if (lines.length <= 1) {
        setState(() => _isImportingCsv = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("The CSV file is empty or only contains headers.")),
          );
        }
        return;
      }

      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
      final response = await ApiClient.postMultipart(
        url,
        filePath: picked.path!,
        fields: {
          "module": "locations_csv",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onChanged?.call();
        await _fetchLiveDrawings();
        if (mounted) {
          setState(() => _isImportingCsv = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Imported ${lines.length - 1} location rows successfully."), backgroundColor: Colors.green),
          );
        }
      } else {
        int importedCount = 0;
        for (int i = 1; i < lines.length; i++) {
          final cols = lines[i].split(',').map((c) => c.trim()).toList();
          if (cols.isNotEmpty && cols[0].isNotEmpty) {
            final blockName = cols[0];
            final levelName = cols.length > 1 ? cols[1] : '';
            if (blockName.isNotEmpty) {
              await ApiClient.post(url, body: {
                "module": "blocks",
                "block_name": blockName,
                "level_names": levelName.isNotEmpty ? [levelName] : [],
              });
              importedCount++;
            }
          }
        }
        widget.onChanged?.call();
        await _fetchLiveDrawings();
        if (mounted) {
          setState(() => _isImportingCsv = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Imported locations successfully ($importedCount items)."), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImportingCsv = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("CSV Import error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = SiteBlockModel.listFromRaw(widget.rawBlocks);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

    // Flatten levels with filtering
    final List<Map<String, dynamic>> flatLevels = [];
    for (var b in blocks) {
      for (var l in b.levels) {
        final key = '${b.name}/${l.name}';
        if (!_isAllSelected && !_selectedLevels.contains(key) && !_selectedBlocks.contains(b.name)) {
          continue;
        }
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final matchLevel = l.name.toLowerCase().contains(q);
          final matchBlock = b.name.toLowerCase().contains(q);
          final matchZones = l.zones.any((z) => z.name.toLowerCase().contains(q));
          if (!matchLevel && !matchBlock && !matchZones) {
            continue;
          }
        }
        flatLevels.add({
          'block': b,
          'level': l,
        });
      }
    }

    return Column(
      children: [
        // Top Toolbar: Site Filter, Search, Apply/Refresh, Reorder, Import, + Add
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Site Filter Trigger + Search Icon + Apply / Refresh
              Row(
                children: [
                  // Site Filter Popover Trigger
                  Expanded(
                    child: InkWell(
                      onTap: () => _showSiteFilterPopover(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _activeSiteFilterSummary,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  fontFamily: 'Inter',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 20, color: textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Search Toggle Icon
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _showSearchBar
                          ? const Color(0xFF0D6EFD).withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: "Search locations",
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    icon: Icon(
                      IconlyLight.search,
                      size: 20,
                      color: _showSearchBar ? const Color(0xFF0D6EFD) : textColor,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Apply Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      widget.onChanged?.call();
                      _fetchLiveDrawings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Filter applied and data refreshed."), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
                  ),
                  const SizedBox(width: 6),

                  // Refresh Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: "Refresh",
                    onPressed: () {
                      widget.onChanged?.call();
                      _fetchLiveDrawings();
                    },
                    icon: Icon(Icons.refresh, size: 20, color: textColor),
                  ),
                ],
              ),

              // Search Bar (if expanded)
              if (_showSearchBar) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search block, level, or zone...",
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: const Icon(IconlyLight.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ],

              const SizedBox(height: 10),

              // Row 2: Action Buttons: Reorder, Import, + Add
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reorder Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showReorderBottomSheet(context),
                    icon: const Icon(IconlyLight.swap, size: 15),
                    label: const Text(
                      "Reorder",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Import Quick Action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(IconlyLight.upload, size: 15),
                    label: const Text(
                      "Import",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // + Add Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showAddActionSheet(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      "Add",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main Scrollable Area
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              widget.onChanged?.call();
              await _fetchLiveDrawings();
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // 1. LOCATIONS / LEVELS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${flatLevels.length} level(s)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (flatLevels.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(IconlyLight.category, size: 40, color: textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          "No locations match active filter.",
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Tap 'Site Filter' above to adjust your selection or '+ Add' to create new blocks.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ...flatLevels.map((item) {
                    final SiteBlockModel block = item['block'];
                    final SiteLevelModel level = item['level'];
                    final matchingDrawings = _findDrawingsForLevel(block.name, level.name, level.id);
                    final drawingCount = matchingDrawings.isNotEmpty ? matchingDrawings.length : level.drawingCount;
                    final firstDrawing = matchingDrawings.isNotEmpty ? matchingDrawings.first : null;
                    final zoneCount = level.zones.length;
                    final firstDrawingUrl = firstDrawing != null
                        ? (firstDrawing['file_url'] ?? firstDrawing['file_path'] ?? firstDrawing['file'] ?? firstDrawing['url'])?.toString()
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Level Title & Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${block.name} | $drawingCount drawing(s) | $zoneCount zone(s)",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textSecondary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Open Button
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    if (widget.projectId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DrawingPinViewerScreen(
                                            projectId: widget.projectId!,
                                            blockName: block.name,
                                            levelName: level.name,
                                            initialDrawing: firstDrawing,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    "Open",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter'),
                                  ),
                                ),

                                const SizedBox(width: 4),

                                // Options Menu ⋮
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: textSecondary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onSelected: (action) async {
                                    if (action == 'add_zone') {
                                      _showAddZoneDialog(context, preselectedBlock: block, preselectedLevel: level);
                                    } else if (action == 'upload_drawing') {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg'],
                                      );
                                      final picked = result?.files.first;
                                      if (picked != null && picked.path != null && widget.projectId != null) {
                                        try {
                                          final url = ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId!);
                                          final response = await ApiClient.postMultipart(
                                            url,
                                            filePath: picked.path!,
                                            fields: {
                                              "module": "drawings",
                                              "level_id": level.id.toString(),
                                              "name": picked.name,
                                            },
                                          );
                                          if (response.statusCode == 200 || response.statusCode == 201) {
                                            widget.onChanged?.call();
                                            _fetchLiveDrawings();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Uploaded '${picked.name}' to ${level.name}."), backgroundColor: Colors.green),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Upload error: $e"), backgroundColor: Colors.redAccent),
                                            );
                                          }
                                        }
                                      }
                                    } else if (action == 'view_drawing') {
                                      _openDrawingFile(firstDrawingUrl);
                                    } else if (action == 'pins') {
                                      if (widget.projectId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DrawingPinViewerScreen(
                                              projectId: widget.projectId!,
                                              blockName: block.name,
                                              levelName: level.name,
                                              initialDrawing: firstDrawing,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'add_zone',
                                      child: Row(
                                        children: [
                                          Icon(IconlyLight.location, size: 18),
                                          SizedBox(width: 8),
                                          Text("Add Zone"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'upload_drawing',
                                      child: Row(
                                        children: [
                                          Icon(IconlyLight.upload, size: 18),
                                          SizedBox(width: 8),
                                          Text("Upload Drawing"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'view_drawing',
                                      child: Row(
                                        children: [
                                          Icon(IconlyLight.show, size: 18),
                                          SizedBox(width: 8),
                                          Text("View Drawing"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'pins',
                                      child: Row(
                                        children: [
                                          Icon(IconlyLight.image, size: 18),
                                          SizedBox(width: 8),
                                          Text("Pins Viewer"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Zone tags wrap
                            if (level.zones.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: level.zones.map((zone) {
                                  final label = zone.zoneCore.isNotEmpty ? "${zone.name} (${zone.zoneCore})" : zone.name;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6EFD).withValues(alpha: isDark ? 0.2 : 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF0D6EFD).withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF0D6EFD)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // 2. DEDICATED "IMPORT DRAWINGS" SECTION (Web Parity)
                Container(
                  key: _importDrawingsSectionKey,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(IconlyLight.image, color: Color(0xFF0D6EFD), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Import Drawings",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Drag and drop one or more drawings from your device, then add them to a selected level. Supports PDFs, CAD files and images.",
                        style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      // Select Level Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedImportLevelKey,
                        hint: Text("Select level", style: TextStyle(color: textSecondary, fontSize: 13)),
                        decoration: InputDecoration(
                          labelText: "Target Level *",
                          labelStyle: TextStyle(color: textColor, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                        items: [
                          for (var b in blocks)
                            for (var l in b.levels)
                              DropdownMenuItem<String>(
                                value: l.id > 0 ? l.id.toString() : '${b.name}:${l.name}',
                                child: Text("${b.name} > ${l.name}", style: TextStyle(color: textColor, fontSize: 13)),
                              ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedImportLevelKey = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // File Dropzone / Picker Box
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg'],
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() {
                              _selectedDrawingFile = result.files.first;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDrawingFile != null ? const Color(0xFF0D6EFD) : (isDark ? Colors.white24 : Colors.grey.shade300),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF0D6EFD)),
                              ),
                              const SizedBox(height: 12),
                              if (_selectedDrawingFile != null) ...[
                                Text(
                                  _selectedDrawingFile!.name,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(_selectedDrawingFile!.size / 1024).toStringAsFixed(1)} KB",
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDrawingFile = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                                  label: const Text("Remove File", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),
                              ] else ...[
                                Text(
                                  "Drag & drop drawings here",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "or click to browse - PDFs, CAD files and images",
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "No files selected yet.",
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upload Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isUploadingDrawing ? null : _uploadDrawingForSelectedLevel,
                        child: _isUploadingDrawing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Upload",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. DEDICATED "CSV TEMPLATE" SECTION (Web Parity)
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(IconlyLight.document, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "CSV Template",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Download the template or bulk upload site locations (Block, Level, Zone, Zone Core) directly.",
                        style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Download Template Button
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _downloadCsvTemplate,
                              icon: const Icon(IconlyLight.download, size: 16),
                              label: const Text(
                                "Download Template",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Import CSV Button
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isImportingCsv ? null : _importCsvFile,
                              icon: _isImportingCsv
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(IconlyLight.upload, size: 16),
                              label: Text(
                                _isImportingCsv ? "Importing..." : "Import CSV",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
