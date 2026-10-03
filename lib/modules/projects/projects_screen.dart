import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import 'project_controller.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends StatefulWidget {
  final Client? filterClient;
  const ProjectsScreen({super.key, this.filterClient});

  @override
  State<ProjectsScreen> createState() => ProjectsScreenState();
}

class ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectController _controller = ProjectController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isSearchVisible = true;

  String _selectedStatus = 'All Projects';
  String _selectedClient = 'All Clients';

  final List<String> _statusOptions = [
    'All Projects',
    'Active',
    'In Progress',
    'Completed',
    'On Hold',
    'Archived',
  ];

  void toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.filterClient != null) {
      _selectedClient = widget.filterClient!.name;
    }
    _controller.fetchProjects();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<String> _getClientOptions() {
    final clients = <String>{'All Clients'};
    for (final p in _controller.projects) {
      final name = p.client?.name.trim();
      if (name != null && name.isNotEmpty) {
        clients.add(name);
      }
    }
    return clients.toList();
  }

  List<Project> get _filteredProjects {
    return _controller.projects.where((project) {
      // 1. Status Filter
      if (_selectedStatus != 'All Projects') {
        final s = project.status.toLowerCase();
        final sl = project.statusLabel.toLowerCase();
        final target = _selectedStatus.toLowerCase();
        final matchesStatus = s == target ||
            sl == target ||
            s.replaceAll(' ', '_') == target.replaceAll(' ', '_') ||
            sl.replaceAll(' ', '_') == target.replaceAll(' ', '_') ||
            (target == 'active' &&
                (s == 'active' ||
                    s == 'in_progress' ||
                    sl == 'active' ||
                    sl == 'in progress')) ||
            (target == 'in progress' &&
                (s == 'in_progress' ||
                    s == 'active' ||
                    sl == 'in progress' ||
                    sl == 'active'));
        if (!matchesStatus) return false;
      }

      // 2. Client Filter
      if (_selectedClient != 'All Clients') {
        final cName = project.client?.name.trim().toLowerCase() ?? '';
        if (cName != _selectedClient.trim().toLowerCase()) return false;
      }

      // 3. Search query filter
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final name = project.name.toLowerCase();
        final code = project.code.toLowerCase();
        final client = (project.client?.name ?? '').toLowerCase();
        final owner = (project.ecgManager ?? project.contractor?['name'] ?? '')
            .toString()
            .toLowerCase();
        final matchesQuery = name.contains(query) ||
            code.contains(query) ||
            client.contains(query) ||
            owner.contains(query);
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark
                ? const BorderSide(color: Colors.white24)
                : BorderSide.none,
          ),
          title: Text(
            "Create Project",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Project Name",
              hintStyle: TextStyle(color: textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: isDark ? Colors.white24 : Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final success = await _controller.createProject(name);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    await _controller.fetchProjects();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _controller.errorMessage ??
                              "Failed to create project",
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Create",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final urlStr = '${ApiEndpoints.baseUrl}${ApiEndpoints.projects}?export=csv';
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading projects report...")),
        );
      }
      final response = await ApiClient.get(urlStr);
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/projects_report.csv');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Projects Report CSV',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Download failed. Status: ${response.statusCode}"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e")),
        );
      }
    }
  }

  String _timeAgo(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Recently';
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays >= 365) {
        final years = (diff.inDays / 365).floor();
        return '$years ${years == 1 ? "year" : "years"} ago';
      } else if (diff.inDays >= 30) {
        final months = (diff.inDays / 30).floor();
        return '$months ${months == 1 ? "month" : "months"} ago';
      } else if (diff.inDays > 0) {
        if (diff.inDays == 1) return '1 day ago';
        return '${diff.inDays} days ago';
      } else if (diff.inHours > 0) {
        final mins = diff.inMinutes % 60;
        if (mins > 0) return '${diff.inHours} hours, $mins minutes ago';
        return '${diff.inHours} hours ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return dateTimeStr;
    }
  }

  Future<void> _downloadQrCode(
    BuildContext context,
    String qrData,
    String projectName,
    String projectCode,
  ) async {
    try {
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );
      final picData =
          await painter.toImageData(600, format: ui.ImageByteFormat.png);
      if (picData != null) {
        final bytes = picData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final safeCode =
            projectCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final file = File('${tempDir.path}/qr_$safeCode.png');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '$projectName QR Code ($projectCode)',
          subject: '$projectName QR Code',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export QR code: $e')),
        );
      }
    }
  }

  void _showQrCode(BuildContext context, Project project) {
    if (project.qrPayload == null && project.qrToken == null) return;

    final qrData = project.qrPayload != null
        ? jsonEncode(project.qrPayload)
        : project.qrToken!;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
        final secondaryTextColor =
            isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        final borderColor =
            isDark ? const Color(0xFF2C3E50) : Colors.grey.shade200;

        final clientName = project.client?.name ?? '';
        final subtitle = clientName.isNotEmpty
            ? '${project.code} - $clientName'
            : project.code;

        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark
                ? const BorderSide(color: Colors.white24)
                : BorderSide.none,
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 22,
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Project QR Code",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: secondaryTextColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "Close",
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                project.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "The operative scan will be performed, and then the standard 500m location and assignment rules will apply.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "Download QR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => _downloadQrCode(
                    context,
                    qrData,
                    project.name,
                    project.code,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color badgeColor = const Color(0xFF2E7D32);
    Color badgeBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE8F5E9);
    String label = status.isNotEmpty ? status : 'Active';

    final lower = status.toLowerCase();
    if (lower == 'completed') {
      badgeColor = const Color(0xFF0D6EFD);
      badgeBg = isDark ? const Color(0xFF102A4C) : const Color(0xFFE7F1FF);
    } else if (lower == 'archived') {
      badgeColor = const Color(0xFF556575);
      badgeBg = isDark ? const Color(0xFF22303E) : const Color(0xFFECEFF1);
    } else if (lower == 'on hold' || lower == 'on_hold') {
      badgeColor = const Color(0xFFE65100);
      badgeBg = isDark ? const Color(0xFF3E2818) : const Color(0xFFFFF3E0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final clientOptions = _getClientOptions();
    if (!clientOptions.contains(_selectedClient)) {
      _selectedClient = 'All Clients';
    }

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _controller.fetchProjects(),
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Actions: CSV Export + Create Project
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _exportCsv,
                          icon: Icon(
                            IconlyLight.download,
                            size: 16,
                            color: textColor,
                          ),
                          label: Text(
                            "Export as CSV",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showCreateProjectDialog,
                          icon: const Icon(
                            IconlyLight.plus,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            "Create Project",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter Toolbar (Search, Status Dropdown, Client Dropdown, Filter Button, Refresh)
                    if (_isSearchVisible)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Search Field
                                SizedBox(
                                  width: 180,
                                  height: 38,
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(() {}),
                                    onSubmitted: (val) => setState(() {}),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Search projects...",
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.grey.shade400,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 18,
                                        color: textSecondary,
                                      ),
                                      suffixIcon: _searchController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                size: 16,
                                                color: textSecondary,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        borderSide:
                                            BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        borderSide:
                                            BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(6)),
                                        borderSide: BorderSide(
                                            color: Color(0xFF0D6EFD)),
                                      ),
                                    ),
                                  ),
                                ),

                                // Status Dropdown
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F253E)
                                        : Colors.white,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: isDark
                                          ? const Color(0xFF162A42)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      value: _selectedStatus,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textColor,
                                      ),
                                      icon: Icon(
                                        IconlyLight.arrow_down_2,
                                        size: 14,
                                        color: textSecondary,
                                      ),
                                      items: _statusOptions
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      e == _selectedStatus
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF0F2C4A),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                              () => _selectedStatus = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                // Client Dropdown
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F253E)
                                        : Colors.white,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      dropdownColor: isDark
                                          ? const Color(0xFF162A42)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      value: _selectedClient,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textColor,
                                      ),
                                      icon: Icon(
                                        IconlyLight.arrow_down_2,
                                        size: 14,
                                        color: textSecondary,
                                      ),
                                      items: clientOptions
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 140),
                                                child: Text(
                                                  e,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        e == _selectedClient
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F2C4A),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                              () => _selectedClient = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),

                                // Filter Button
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF0D6EFD),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () => setState(() {}),
                                    child: const Text(
                                      "Filter",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Reset / Refresh Icon
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _selectedStatus = 'All Projects';
                                      _selectedClient = 'All Clients';
                                    });
                                    _controller.fetchProjects();
                                  },
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: textColor,
                                    size: 20,
                                  ),
                                  tooltip: "Reset Filters",
                                ),
                              ],
                            ),

                            // Result Count Indicator
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final count = _filteredProjects.length;
                                return Text(
                                  count > 0
                                      ? "1 - $count of $count"
                                      : "0 of 0",
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Main Projects Table matching Web Admin
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        if (_controller.isLoading &&
                            _controller.projects.isEmpty) {
                          return Column(
                            children: List.generate(
                              4,
                              (index) => Container(
                                height: 56,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                              ),
                            ),
                          );
                        }

                        final projects = _filteredProjects;

                        if (projects.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  IconlyLight.folder,
                                  size: 48,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No projects found",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Try adjusting your filters or search query.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth:
                                      MediaQuery.of(context).size.width - 32,
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFF0F253E),
                                  ),
                                  headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                  dataTextStyle: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                  dividerThickness: 1,
                                  horizontalMargin: 16,
                                  columnSpacing: 20,
                                  headingRowHeight: 46,
                                  dataRowMinHeight: 54,
                                  dataRowMaxHeight: 64,
                                  columns: const [
                                    DataColumn(
                                      label: Row(
                                        children: [
                                          Icon(
                                            Icons.radio_button_unchecked,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 8),
                                          Text("PROJECT"),
                                        ],
                                      ),
                                    ),
                                    DataColumn(label: Text("STATUS")),
                                    DataColumn(label: Text("CLIENT")),
                                    DataColumn(label: Text("OWNER")),
                                    DataColumn(label: Text("LOCATIONS")),
                                    DataColumn(label: Text("QR CODE")),
                                    DataColumn(label: Text("LAST ACTIVITY")),
                                    DataColumn(label: Text("TEAM")),
                                  ],
                                  rows: projects.map((project) {
                                    final displayName = project.code.isNotEmpty
                                        ? '${project.name} (${project.code})'
                                        : project.name;
                                    final clientName =
                                        project.client?.name ?? '—';
                                    final owner = project.ecgManager ??
                                        project.contractor?['name'] ??
                                        'Not assigned';
                                    final locations =
                                        project.siteAddress.isNotEmpty
                                            ? '1'
                                            : '1';
                                    final lastActivity = _timeAgo(
                                        project.updatedAt ??
                                            project.createdAt);
                                    final status =
                                        project.statusLabel.isNotEmpty
                                            ? project.statusLabel
                                            : (project.status.isNotEmpty
                                                ? project.status
                                                : 'Active');

                                    return DataRow(
                                      cells: [
                                        // Project Name & Code
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.radio_button_unchecked,
                                                size: 16,
                                                color: isDark
                                                    ? Colors.white38
                                                    : Colors.grey.shade400,
                                              ),
                                              const SizedBox(width: 10),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                  maxWidth: 220,
                                                ),
                                                child: Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: textColor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Status badge
                                        DataCell(
                                          _buildStatusBadge(status, isDark),
                                        ),

                                        // Client
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 160),
                                            child: Text(
                                              clientName,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Owner
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.account_circle_outlined,
                                                size: 16,
                                                color: const Color(0xFF0D6EFD),
                                              ),
                                              const SizedBox(width: 6),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 160),
                                                child: Text(
                                                  owner,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: owner ==
                                                            'Not assigned'
                                                        ? textSecondary
                                                        : textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Locations
                                        DataCell(
                                          Text(
                                            locations,
                                            style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),

                                        // QR Code
                                        DataCell(
                                          InkWell(
                                            onTap: () => _showQrCode(
                                                context, project),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.qr_code,
                                                    size: 16,
                                                    color: const Color(
                                                        0xFF0D6EFD),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    "View",
                                                    style: TextStyle(
                                                      color: Color(0xFF0D6EFD),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Last Activity
                                        DataCell(
                                          Text(
                                            lastActivity,
                                            style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 12),
                                          ),
                                        ),

                                        // Team actions
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  side: BorderSide(
                                                      color: borderColor),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProjectDetailsScreen(
                                                        project: project,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.person_add_alt_1_outlined,
                                                  size: 13,
                                                  color: textColor,
                                                ),
                                                label: Text(
                                                  "Assign",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              OutlinedButton.icon(
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  side: BorderSide(
                                                      color: borderColor),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProjectDetailsScreen(
                                                        project: project,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.group_outlined,
                                                  size: 13,
                                                  color: textColor,
                                                ),
                                                label: Text(
                                                  "View",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
