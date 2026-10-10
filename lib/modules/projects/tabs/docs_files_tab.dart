import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/date_helper.dart';

class DocsFilesTab extends StatefulWidget {
  final int projectId;
  final List<dynamic> folders;
  final List<dynamic> files;
  final VoidCallback? onChanged;

  const DocsFilesTab({
    super.key,
    required this.projectId,
    required this.folders,
    required this.files,
    this.onChanged,
  });

  @override
  State<DocsFilesTab> createState() => _DocsFilesTabState();
}

class _DocsFilesTabState extends State<DocsFilesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isBusy = false;

  late List<dynamic> _localFolders;
  late List<dynamic> _localFiles;

  int? _openedFolderId;
  String? _openedFolderName;
  String? _openedFolderType;

  final Set<int> _expandedFolderIds = {};

  String get _baseUrl =>
      ApiEndpoints.baseUrl +
      ApiEndpoints.projectAllInOneDetails(widget.projectId);

  @override
  void initState() {
    super.initState();
    _localFolders = List.from(widget.folders);
    _localFiles = List.from(widget.files);
    _expandRootFolders();

    if (_localFolders.isEmpty && _localFiles.isEmpty) {
      _fetchTabFiles();
    }
  }

  void _expandRootFolders() {
    for (var f in _localFolders) {
      if (f is Map) {
        final id = f['id'] is int
            ? f['id']
            : int.tryParse(f['id']?.toString() ?? '');
        if (id != null) {
          _expandedFolderIds.add(id);
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant DocsFilesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folders != widget.folders ||
        oldWidget.files != widget.files) {
      _localFolders = List.from(widget.folders);
      _localFiles = List.from(widget.files);
      _expandRootFolders();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTabFiles() async {
    try {
      final tz = await DateHelper.getDeviceTimezone();
      final queryParam = tz.isNotEmpty ? '?tz=${Uri.encodeComponent(tz)}' : '';
      final response = await ApiClient.get(_baseUrl + queryParam);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final resData = data['data'];
          if (mounted) {
            setState(() {
              _localFolders = (resData['docs_folders'] ??
                  resData['folders'] ??
                  resData['doc_folders'] as List? ??
                  []);
              _localFiles = (resData['docs_files'] ??
                  resData['files'] ??
                  resData['documents'] ??
                  resData['doc_files'] as List? ??
                  []);
              _expandRootFolders();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching docs & files: $e");
    }
    widget.onChanged?.call();
  }

  String _getFileName(dynamic file) {
    if (file is Map) {
      return (file['title'] ??
              file['name'] ??
              file['file_name'] ??
              file['filename'] ??
              'Untitled file')
          .toString();
    }
    return file?.toString() ?? 'Untitled file';
  }

  String _getFileUrl(dynamic file) {
    if (file is Map) {
      return (file['file_url'] ??
              file['url'] ??
              file['file'] ??
              file['path'] ??
              '')
          .toString();
    }
    return '';
  }

  String _getFileDate(dynamic file) {
    if (file is Map) {
      final raw = file['created_at'] ??
          file['uploaded_at'] ??
          file['created'] ??
          file['date'] ??
          file['timestamp'];
      if (raw != null) {
        return DateHelper.formatToLocal(raw.toString(), includeTime: true);
      }
    }
    return '';
  }

  int? _getFileId(dynamic file) {
    if (file is Map) {
      final id = file['id'] ?? file['file_id'];
      if (id is int) return id;
      if (id != null) return int.tryParse(id.toString());
    }
    return null;
  }

  int? _getFileFolderId(dynamic file) {
    if (file is Map) {
      final fid = file['folder_id'] ?? file['folder'];
      if (fid is int) return fid;
      if (fid != null && fid != 'null') return int.tryParse(fid.toString());
    }
    return null;
  }

  String _getFileFolderType(dynamic file) {
    if (file is Map) {
      return (file['folder_type'] ?? file['type'] ?? 'files').toString();
    }
    return 'files';
  }

  Set<int> _getAllDescendantFolderIds(int folderId) {
    final result = <int>{folderId};
    final children = _localFolders.where((f) {
      if (f is! Map) return false;
      final pId = f['parent_id'] ?? f['parent'];
      final pIdInt = pId is int
          ? pId
          : (pId != null ? int.tryParse(pId.toString()) : null);
      return pIdInt == folderId;
    }).toList();

    for (var child in children) {
      final cId = child is Map
          ? (child['id'] is int
              ? child['id']
              : int.tryParse(child['id']?.toString() ?? ''))
          : null;
      if (cId != null && !result.contains(cId)) {
        result.addAll(_getAllDescendantFolderIds(cId));
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _getFolderSubfolders(Map<String, dynamic> folder) {
    final folderId = folder['id'] is int
        ? folder['id']
        : int.tryParse(folder['id']?.toString() ?? '');

    final embedded = (folder['subfolders'] ??
            folder['children'] ??
            folder['sub_folders'] as List? ??
            [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    if (embedded.isNotEmpty) return embedded;

    if (folderId != null) {
      return _localFolders.where((f) {
        if (f is! Map) return false;
        final pId = f['parent_id'] ?? f['parent'];
        final pIdInt = pId is int
            ? pId
            : (pId != null ? int.tryParse(pId.toString()) : null);
        return pIdInt == folderId;
      }).map((f) => (f as Map).cast<String, dynamic>()).toList();
    }
    return [];
  }

  List<dynamic> _getFolderDirectFiles(Map<String, dynamic> folder) {
    final folderId = folder['id'] is int
        ? folder['id']
        : int.tryParse(folder['id']?.toString() ?? '');

    final directList =
        (folder['files'] ?? folder['documents'] as List? ?? []).toList();
    if (directList.isNotEmpty) return directList;

    if (folderId != null) {
      return _localFiles
          .where((f) => _getFileFolderId(f) == folderId)
          .toList();
    }
    return [];
  }

  int _getFolderTotalFilesCount(Map<String, dynamic> folder) {
    final folderId = folder['id'] is int
        ? folder['id']
        : int.tryParse(folder['id']?.toString() ?? '');
    if (folderId == null) return 0;
    final allIds = _getAllDescendantFolderIds(folderId);
    return _localFiles.where((f) {
      final fid = _getFileFolderId(f);
      return fid != null && allIds.contains(fid);
    }).length;
  }

  Future<void> _createFolder(
      String folderType, String name, bool isPrivate, {int? parentId}) async {
    setState(() => _isBusy = true);
    try {
      final response = await ApiClient.post(_baseUrl, body: {
        "module": "folders",
        "name": name,
        "folder_type": folderType,
        "is_private": isPrivate,
        if (parentId != null) "parent_id": parentId,
      });
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchTabFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Folder '$name' created successfully."),
                backgroundColor: Colors.green),
          );
        }
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Folder"),
        content: const Text(
            "Are you sure you want to delete this folder and all its contents? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final deleteUrl =
          "$_baseUrl?module=folders&folder_id=$folderId&delete=true";
      final response = await ApiClient.delete(deleteUrl);
      if (!mounted) return;
      if (response.statusCode == 200) {
        if (_openedFolderId == folderId) {
          _openedFolderId = null;
          _openedFolderName = null;
          _openedFolderType = null;
        }
        await _fetchTabFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Folder deleted successfully."),
                backgroundColor: Colors.green),
          );
        }
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete File"),
        content: const Text(
            "Are you sure you want to delete this file? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final deleteUrl = "$_baseUrl?module=files&file_id=$fileId&delete=true";
      final response = await ApiClient.delete(deleteUrl);
      if (!mounted) return;
      if (response.statusCode == 200) {
        // Same reasoning as upload: remove it from local state right away
        // rather than waiting on a full (and comparatively heavy)
        // project-detail refetch before the counter reflects the delete.
        setState(() {
          _localFiles = _localFiles.where((f) => _getFileId(f) != fileId).toList();
        });
        unawaited(_fetchTabFiles());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("File deleted successfully."),
                backgroundColor: Colors.green),
          );
        }
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showFilesDialog(
      BuildContext context, String title, String folderType) {
    final matching = _localFiles.where((f) {
      final isSignedDoc = _getFileFolderType(f) == 'signed_docs';
      if (folderType == 'signed_docs') {
        return isSignedDoc;
      } else {
        return !isSignedDoc;
      }
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;
        final textColor =
            isDark ? Colors.white : const Color(0xFF0F2C4A);
        final textSecondary =
            isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        final dialogWidth =
            MediaQuery.of(dialogContext).size.width * 0.9;

        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(IconlyLight.folder,
                  size: 20,
                  color: isDark ? Colors.orange.shade300 : Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${matching.length}",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textSecondary),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth.clamp(320.0, 520.0),
            child: matching.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(IconlyLight.document,
                              size: 40,
                              color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text("No files here yet.",
                              style: TextStyle(
                                  color: textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 380,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: matching.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        return _buildFileItem(context, matching[index],
                            isDark, textColor, textSecondary);
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Close",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showNewFolderDialog(String folderType, {int? parentId}) {
    final folderNameController = TextEditingController();
    bool isPrivate = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor:
                  isDark ? AppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                "New Folder",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: folderNameController,
                    autofocus: true,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Folder name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Make Folder Private",
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87)),
                      Switch(
                        value: isPrivate,
                        onChanged: (val) =>
                            setDialogState(() => isPrivate = val),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white),
                  onPressed: () {
                    final name = folderNameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(dialogContext);
                    _createFolder(folderType, name, isPrivate,
                        parentId: parentId);
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
    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }
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
        // Insert the uploaded file into local state immediately instead of
        // waiting on a full project-detail refetch - that request fetches
        // the entire project (specs, drawings, job sheets, HSE, ...), not
        // just this tab's files, so the folder's item counter used to sit
        // stale until that whole round-trip finished.
        final decoded = jsonDecode(response.body);
        final uploaded = decoded['data'];
        if (uploaded is Map) {
          setState(() {
            _localFiles = [..._localFiles, Map<String, dynamic>.from(uploaded)];
          });
        }
        unawaited(_fetchTabFiles());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Uploaded '${file.name}' successfully."),
                backgroundColor: Colors.green),
          );
        }
      } else {
        _showError("Failed to upload '${file.name}'.");
      }
    } catch (e) {
      if (mounted) _showError("Failed to upload file: $e");
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Filter root folders
    final signedDocsRootFolders = _localFolders.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      final pId = fMap['parent_id'] ?? fMap['parent'];
      return fMap['folder_type'] == 'signed_docs' && pId == null;
    }).toList();

    final normalFilesRootFolders = _localFolders.where((f) {
      final fMap = f as Map<String, dynamic>? ?? {};
      final pId = fMap['parent_id'] ?? fMap['parent'];
      return fMap['folder_type'] != 'signed_docs' && pId == null;
    }).toList();

    // Section total files
    final signedDocsAllFiles = _localFiles.where((f) {
      final isSignedDoc = _getFileFolderType(f) == 'signed_docs';
      return isSignedDoc;
    }).toList();

    final normalFilesAllFiles = _localFiles.where((f) {
      final isSignedDoc = _getFileFolderType(f) == 'signed_docs';
      return !isSignedDoc;
    }).toList();

    // Loose root files (files with no folder_id)
    final signedDocsRootFiles = signedDocsAllFiles.where((f) {
      final fid = _getFileFolderId(f);
      return fid == null;
    }).toList();

    final normalFilesRootFiles = normalFilesAllFiles.where((f) {
      final fid = _getFileFolderId(f);
      return fid == null;
    }).toList();

    final totalFilesCount = _localFiles.length;
    final totalFoldersCount = _localFolders.length;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar & Search
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isDesktop
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "$totalFilesCount files in $totalFoldersCount folders",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Copying to another project isn't supported yet.")),
                          );
                        },
                        icon: Icon(IconlyLight.document,
                            size: 14,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF0F2C4A)),
                        label: Text(
                          "Copy to Other Project",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F2C4A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 13),
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Search folders or files",
                              hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade400,
                                  fontSize: 13),
                              prefixIcon: Icon(IconlyLight.search,
                                  size: 16,
                                  color:
                                      isDark ? Colors.white70 : Colors.grey),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: "Refresh",
                        onPressed: _fetchTabFiles,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Area
            Expanded(
              child: _openedFolderId != null
                  ? _buildOpenedFolderView(
                      isDark: isDark,
                      textColor: textColor,
                      textSecondary: textSecondary)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Flex(
                        direction:
                            isDesktop ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SIGNED DOCS Column
                          Expanded(
                            flex: isDesktop ? 1 : 0,
                            child: _buildSectionCard(
                              isDark: isDark,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              title: "SIGNED DOCS",
                              folderType: "signed_docs",
                              rootFolders: signedDocsRootFolders,
                              totalSectionFiles: signedDocsAllFiles.length,
                              rootFiles: signedDocsRootFiles,
                            ),
                          ),
                          SizedBox(
                              width: isDesktop ? 16 : 0,
                              height: isDesktop ? 0 : 20),
                          // FILES Column
                          Expanded(
                            flex: isDesktop ? 1 : 0,
                            child: _buildSectionCard(
                              isDark: isDark,
                              textColor: textColor,
                              textSecondary: textSecondary,
                              title: "FILES",
                              folderType: "files",
                              rootFolders: normalFilesRootFolders,
                              totalSectionFiles: normalFilesAllFiles.length,
                              rootFiles: normalFilesRootFiles,
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

  Widget _buildOpenedFolderView({
    required bool isDark,
    required Color textColor,
    required Color textSecondary,
  }) {
    final folderFiles = _localFiles.where((f) {
      final fid = _getFileFolderId(f);
      final name = _getFileName(f);
      final matchesSearch = _searchQuery.isEmpty ||
          name.toLowerCase().contains(_searchQuery.toLowerCase());
      return fid == _openedFolderId && matchesSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder Breadcrumb Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _openedFolderId = null;
                    _openedFolderName = null;
                    _openedFolderType = null;
                  });
                },
                icon: const Icon(IconlyLight.arrow_left, size: 16),
                label: const Text("Back to Root",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _uploadFile(
                        _openedFolderType ?? 'files',
                        folderId: _openedFolderId),
                    icon: const Icon(IconlyLight.upload, size: 14),
                    label: const Text("Upload File",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(IconlyLight.delete,
                        size: 18, color: Colors.red),
                    tooltip: "Delete Folder",
                    onPressed: () => _deleteFolder(_openedFolderId!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(IconlyLight.folder,
                  color:
                      isDark ? Colors.orange.shade300 : Colors.orange,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                "${_openedFolderName ?? 'Folder'} (${folderFiles.length} files)",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: folderFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconlyLight.document,
                            size: 48,
                            color: textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text("No files in this folder.",
                            style: TextStyle(
                                color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: folderFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildFileItem(context, folderFiles[index],
                          isDark, textColor, textSecondary);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Color textColor,
    required Color textSecondary,
    required String title,
    required String folderType,
    required List<dynamic> rootFolders,
    required int totalSectionFiles,
    required List<dynamic> rootFiles,
  }) {
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header (With bounded Expanded Row to avoid horizontal overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.folder, size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$totalSectionFiles",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(IconlyLight.folder, size: 18),
                    onPressed: () => _showNewFolderDialog(folderType),
                    tooltip: "New Folder",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(IconlyLight.upload, size: 18),
                    onPressed: () => _uploadFile(folderType),
                    tooltip: "Upload File",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(IconlyLight.show, size: 18),
                    onPressed: () =>
                        _showFilesDialog(context, title, folderType),
                    tooltip: "View Files",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Folder Tree (Folders & Subfolders & Files)
          if (rootFolders.isNotEmpty) ...[
            ...rootFolders.map((f) => _buildFolderTreeNode(
                  context,
                  folder: f as Map<String, dynamic>,
                  depth: 0,
                  isDark: isDark,
                  textColor: textColor,
                  textSecondary: textSecondary,
                )),
            const SizedBox(height: 8),
          ] else
            _buildEmptyDashedState(
              context,
              label: title == "SIGNED DOCS"
                  ? "New Signed Docs Folder"
                  : "New Folder",
              onTap: () => _showNewFolderDialog(folderType),
            ),

          // Loose Root Files (if any)
          if (rootFiles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              "FILES (${rootFiles.length})",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade100),
                color: isDark
                    ? Colors.black12
                    : Colors.grey.shade50.withValues(alpha: 0.5),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rootFiles.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade200),
                itemBuilder: (context, index) {
                  return _buildFileItem(context, rootFiles[index], isDark,
                      textColor, textSecondary);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDashedState(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.folder,
                size: 18,
                color: isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTreeNode(
    BuildContext context, {
    required Map<String, dynamic> folder,
    required int depth,
    required bool isDark,
    required Color textColor,
    required Color textSecondary,
  }) {
    final folderId = folder['id'] is int
        ? folder['id']
        : int.tryParse(folder['id']?.toString() ?? '');
    final name = folder['name']?.toString() ?? 'Folder';
    final folderType = folder['folder_type']?.toString() ?? 'files';

    final subfolders = _getFolderSubfolders(folder);
    final directFiles = _getFolderDirectFiles(folder);
    final totalFiles = _getFolderTotalFilesCount(folder);

    final isExpanded =
        folderId != null && _expandedFolderIds.contains(folderId);
    final hasContent = subfolders.isNotEmpty || directFiles.isNotEmpty;

    final paddingLeft = (depth * 14.0) + 8.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: depth == 0 ? 0.04 : 0.02)
            : (depth == 0 ? Colors.grey.shade50 : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Folder Header Row
          InkWell(
            onTap: () {
              if (folderId != null) {
                setState(() {
                  if (_expandedFolderIds.contains(folderId)) {
                    _expandedFolderIds.remove(folderId);
                  } else {
                    _expandedFolderIds.add(folderId);
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.fromLTRB(paddingLeft, 10, 8, 10),
              child: Row(
                children: [
                  Icon(
                    hasContent
                        ? (isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right)
                        : IconlyLight.folder,
                    size: 18,
                    color: isDark
                        ? Colors.orange.shade300
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    IconlyLight.folder,
                    size: 16,
                    color: isDark
                        ? Colors.orange.shade300
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (subfolders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${subfolders.length} sub",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D6EFD),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          "$totalFiles",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (folder['is_private'] == true)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(IconlyLight.lock,
                          size: 14, color: Colors.grey),
                    ),
                  IconButton(
                    icon: const Icon(IconlyLight.folder, size: 15),
                    tooltip: "New Subfolder",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _showNewFolderDialog(folderType,
                        parentId: folderId),
                  ),
                  IconButton(
                    icon: const Icon(IconlyLight.upload, size: 15),
                    tooltip: "Upload into folder",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () =>
                        _uploadFile(folderType, folderId: folderId),
                  ),
                  IconButton(
                    icon: const Icon(IconlyLight.delete,
                        size: 15, color: Colors.red),
                    tooltip: "Delete folder",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      if (folderId != null) _deleteFolder(folderId);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content: Subfolders and Files
          if (isExpanded) ...[
            if (subfolders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 8, 4),
                child: Column(
                  children: subfolders
                      .map((sub) => _buildFolderTreeNode(
                            context,
                            folder: sub,
                            depth: depth + 1,
                            isDark: isDark,
                            textColor: textColor,
                            textSecondary: textSecondary,
                          ))
                      .toList(),
                ),
              ),
            if (directFiles.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(paddingLeft + 10, 0, 8, 6),
                child: Column(
                  children: directFiles
                      .map((file) => _buildFileItem(context, file, isDark,
                          textColor, textSecondary))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    dynamic file,
    bool isDark,
    Color textColor,
    Color textSecondary,
  ) {
    final name = _getFileName(file);
    final url = _getFileUrl(file);
    final date = _getFileDate(file);
    final fileId = _getFileId(file);
    final canOpen = url.startsWith('http');

    return Tooltip(
      message: name,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(IconlyLight.document,
                  size: 16, color: Color(0xFF0D6EFD)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.25,
                    ),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canOpen)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(40, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication),
                    child: const Text("View",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                if (fileId != null)
                  IconButton(
                    icon: const Icon(IconlyLight.delete,
                        size: 16, color: Colors.red),
                    tooltip: "Delete File",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _deleteFile(fileId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
