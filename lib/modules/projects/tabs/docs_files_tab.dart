import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Real folders/files for a project, backed by ProjectAllInOneDetailAPIView's
/// already-built module=folders/module=files POST+DELETE actions (the
/// backend was complete; this tab previously only ever mutated local,
/// never-persisted state).
class DocsFilesTab extends StatefulWidget {
  final int projectId;
  final List<dynamic> folders;
  final List<dynamic> files;
  final VoidCallback? onChanged;

  const DocsFilesTab({
    Key? key,
    required this.projectId,
    required this.folders,
    required this.files,
    this.onChanged,
  }) : super(key: key);

  @override
  State<DocsFilesTab> createState() => _DocsFilesTabState();
}

class _DocsFilesTabState extends State<DocsFilesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isBusy = false;

  String get _baseUrl => ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(widget.projectId);

  Future<void> _createFolder(String folderType, String name, bool isPrivate) async {
    setState(() => _isBusy = true);
    try {
      final response = await ApiClient.post(_baseUrl, body: {
        "module": "folders",
        "name": name,
        "folder_type": folderType,
        "is_private": isPrivate,
      });
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onChanged?.call();
      } else {
        _showError("Failed to create folder.");
      }
    } catch (e) {
      if (mounted) _showError("Failed to create folder: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteFolder(int folderId) async {
    setState(() => _isBusy = true);
    try {
      final response = await ApiClient.delete('$_baseUrl?module=folders&folder_id=$folderId');
      if (!mounted) return;
      if (response.statusCode == 200) {
        widget.onChanged?.call();
      } else {
        _showError("Failed to delete folder.");
      }
    } catch (e) {
      if (mounted) _showError("Failed to delete folder: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteFile(int fileId) async {
    setState(() => _isBusy = true);
    try {
      final response = await ApiClient.delete('$_baseUrl?module=files&file_id=$fileId');
      if (!mounted) return;
      if (response.statusCode == 200) {
        widget.onChanged?.call();
      } else {
        _showError("Failed to delete file.");
      }
    } catch (e) {
      if (mounted) _showError("Failed to delete file: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showNewFolderDialog(String folderType) {
    final folderNameController = TextEditingController();
    bool isPrivate = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "New Folder",
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: folderNameController,
                    autofocus: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Folder name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Make Folder Private", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      Switch(
                        value: isPrivate,
                        onChanged: (val) => setDialogState(() => isPrivate = val),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), foregroundColor: Colors.white),
                  onPressed: () {
                    final name = folderNameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(dialogContext);
                    _createFolder(folderType, name, isPrivate);
                  },
                  child: const Text("Add Folder"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadFile(String folderType, {int? folderId}) async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    final file = result.files.first;

    setState(() => _isBusy = true);
    try {
      final response = await ApiClient.postMultipart(
        _baseUrl,
        filePath: file.path!,
        fields: {
          "module": "files",
          "title": file.name,
          "folder_type": folderType,
          if (folderId != null) "folder_id": folderId.toString(),
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Uploaded '${file.name}' successfully."), backgroundColor: Colors.green),
        );
      } else {
        _showError("Failed to upload '${file.name}'.");
      }
    } catch (e) {
      if (mounted) _showError("Failed to upload file: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showFilesDialog(BuildContext context, String title, String folderType) {
    final matching = widget.files.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      return (fMap['folder_type']?.toString() ?? '') == folderType;
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: matching.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text("No files here yet.", style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  )
                : SizedBox(
                    height: 320,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: matching.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = matching[index] as Map<String, dynamic>;
                        final name = file['title']?.toString() ?? 'Untitled file';
                        final url = file['file_url']?.toString() ?? '';
                        final canOpen = url.startsWith('http');
                        return ListTile(
                          leading: const Icon(IconlyLight.document),
                          title: Text(name, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: canOpen ? () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) : null,
                                child: const Text("View"),
                              ),
                              IconButton(
                                icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  await _deleteFile(file['id'] as int);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Close")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    final signedDocsFolders = widget.folders.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      final name = fMap['name']?.toString() ?? '';
      final matchesSearch = _searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery.toLowerCase());
      return fMap['folder_type'] == 'signed_docs' && fMap['parent_id'] == null && matchesSearch;
    }).toList();

    final normalFilesFolders = widget.folders.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      final name = fMap['name']?.toString() ?? '';
      final matchesSearch = _searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery.toLowerCase());
      return fMap['folder_type'] == 'files' && fMap['parent_id'] == null && matchesSearch;
    }).toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Copying to another project isn't built yet.")),
                          );
                        },
                        icon: Icon(IconlyLight.document, size: 16, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
                        label: Text(
                          "Copy to Other Project",
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F2C4A), fontWeight: FontWeight.bold),
                        ),
                      ),
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
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Search folders",
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: _buildColumn(
                        isDark: isDark,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        title: "SIGNED DOCS",
                        folderType: "signed_docs",
                        folders: signedDocsFolders,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 24),
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: _buildColumn(
                        isDark: isDark,
                        textColor: textColor,
                        textSecondary: textSecondary,
                        title: "FILES",
                        folderType: "files",
                        folders: normalFilesFolders,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isBusy)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildColumn({
    required bool isDark,
    required Color textColor,
    required Color textSecondary,
    required String title,
    required String folderType,
    required List<dynamic> folders,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(IconlyLight.folder, size: 16, color: textSecondary),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("${folders.length}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary)),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(IconlyLight.folder, size: 16),
                  onPressed: () => _showNewFolderDialog(folderType),
                  tooltip: "New Folder",
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(IconlyLight.upload, size: 16),
                  onPressed: () => _uploadFile(folderType),
                  tooltip: "Upload",
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(IconlyLight.show, size: 16),
                  onPressed: () => _showFilesDialog(context, title, folderType),
                  tooltip: "View Files",
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (folders.isEmpty)
          _buildEmptyDashedState(context, label: "New Folder", onTap: () => _showNewFolderDialog(folderType))
        else
          ...folders.map((f) => _buildFolderCard(context, f as Map<String, dynamic>)),
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
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, Map<String, dynamic> folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    final filesInFolder = widget.files.where((f) => (f as Map)['folder_id'] == folder['id']).length;

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
              '${folder['name']?.toString() ?? 'Unnamed Folder'} ($filesInFolder)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          if (folder['is_private'] == true) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(IconlyLight.lock, size: 16, color: Colors.grey)),
          IconButton(
            icon: const Icon(IconlyLight.upload, size: 16),
            tooltip: "Upload into this folder",
            onPressed: () => _uploadFile(folder['folder_type']?.toString() ?? 'files', folderId: folder['id'] as int),
          ),
          IconButton(
            icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
            tooltip: "Delete folder",
            onPressed: () => _deleteFolder(folder['id'] as int),
          ),
        ],
      ),
    );
  }
}
