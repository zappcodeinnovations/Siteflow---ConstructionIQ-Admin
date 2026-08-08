import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';

class DocsFilesTab extends StatefulWidget {
  final List<dynamic> folders;
  final List<dynamic> files;

  const DocsFilesTab({
    Key? key,
    required this.folders,
    required this.files,
  }) : super(key: key);

  @override
  State<DocsFilesTab> createState() => _DocsFilesTabState();
}

class _DocsFilesTabState extends State<DocsFilesTab> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _localFolders = [];
  List<dynamic> _localFiles = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _localFolders = List.from(widget.folders);
    _localFiles = List.from(widget.files);
  }

  void _showNewFolderDialog([String? defaultParent]) {
    final folderNameController = TextEditingController();
    String selectedParent = defaultParent ?? "Files";
    bool isPrivate = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(IconlyLight.folder, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
                      const SizedBox(width: 8),
                      Text(
                        "New Folder",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Parent Folder",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                        isExpanded: true,
                        value: selectedParent,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        items: ["Signed Documents", "Files"]
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedParent = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Folder Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: folderNameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Folder name",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Make Folder Private",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Switch(
                        value: isPrivate,
                        activeColor: const Color(0xFF0D6EFD),
                        onChanged: (val) {
                          setDialogState(() {
                            isPrivate = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 24, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    final name = folderNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter folder name")),
                      );
                      return;
                    }
                    setState(() {
                      _localFolders.add({
                        "id": DateTime.now().millisecondsSinceEpoch,
                        "name": name,
                        "parent": selectedParent,
                        "is_private": isPrivate,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Add Folder",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _uploadFile(String folderType) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final fileName = result.files.first.name;
      setState(() {
        _localFiles.add({
          "id": DateTime.now().millisecondsSinceEpoch,
          "file_name": fileName,
          "folder_type": folderType,
          "file_path": "Local upload",
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Uploaded '$fileName' successfully.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Filter Signed Docs and Files based on search and folder mapping
    final signedDocsFolders = _localFolders.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      final parent = fMap['parent']?.toString() ?? '';
      final name = fMap['name']?.toString() ?? '';
      final matchesSearch = _searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery.toLowerCase());
      return parent == "Signed Documents" && matchesSearch;
    }).toList();

    final normalFilesFolders = _localFolders.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      final parent = fMap['parent']?.toString() ?? '';
      final name = fMap['name']?.toString() ?? '';
      final matchesSearch = _searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery.toLowerCase());
      return (parent == "Files" || parent.isEmpty) && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
            children: [
              // Count details
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       "Docs & Files",
              //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              //     ),
              //     const SizedBox(height: 4),
              //     Text(
              //       "${_localFiles.length} files in ${_localFolders.length} folders",
              //       style: TextStyle(fontSize: 12, color: textSecondary),
              //     ),
              //   ],
              // ),
              // SizedBox(height: isDesktop ? 0 : 16),
              // Search & Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Mocking: Copying to other projects...")),
                      );
                    },
                    icon: Icon(IconlyLight.document, size: 16, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
                    label: Text(
                      "Copy to Other Project",
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F2C4A), fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _showNewFolderDialog(),
                    icon: const Icon(IconlyLight.plus, size: 16),
                    label: const Text("New Folder", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  // Search Bar
                  Container(
                    width: isDesktop ? 220 : double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: "Search folders or files",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                        prefixIcon: Icon(IconlyLight.search, size: 16, color: isDark ? Colors.white70 : Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Grid Area for Columns
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: SIGNED DOCS
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(IconlyLight.folder, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                "SIGNED DOCS",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${signedDocsFolders.length}",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary),
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(IconlyLight.folder, size: 16),
                                onPressed: () => _showNewFolderDialog("Signed Documents"),
                                tooltip: "New Signed Folder",
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(IconlyLight.upload, size: 16),
                                onPressed: () => _uploadFile("Signed Documents"),
                                tooltip: "Upload Doc",
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(IconlyLight.show, size: 16),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (signedDocsFolders.isEmpty)
                        _buildEmptyDashedState(
                          context,
                          label: "New Signed Docs Folder",
                          onTap: () => _showNewFolderDialog("Signed Documents"),
                        )
                      else
                        ...signedDocsFolders.map((f) => _buildFolderCard(context, f as Map<String, dynamic>)),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 24),
                // Column 2: FILES
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(IconlyLight.folder, size: 16, color: textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                "FILES",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${normalFilesFolders.length}",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary),
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(IconlyLight.folder, size: 16),
                                onPressed: () => _showNewFolderDialog("Files"),
                                tooltip: "New Folder",
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(IconlyLight.upload, size: 16),
                                onPressed: () => _uploadFile("Files"),
                                tooltip: "Upload File",
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(IconlyLight.show, size: 16),
                                onPressed: () {},
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (normalFilesFolders.isEmpty)
                        _buildEmptyDashedState(
                          context,
                          label: "New Folder",
                          onTap: () => _showNewFolderDialog("Files"),
                        )
                      else
                        ...normalFilesFolders.map((f) => _buildFolderCard(context, f as Map<String, dynamic>)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDashedState(BuildContext context, {required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, style: BorderStyle.solid, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.folder, size: 18, color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, Map<String, dynamic> folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(IconlyLight.folder, color: isDark ? Colors.orange.shade300 : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              folder['name']?.toString() ?? 'Unnamed Folder',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          if (folder['is_private'] == true)
            const Icon(IconlyLight.lock, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
