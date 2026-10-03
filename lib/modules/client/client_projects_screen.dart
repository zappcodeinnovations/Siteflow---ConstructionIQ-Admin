import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../projects/project_controller.dart';

class ClientProjectsScreen extends StatefulWidget {
  final Client client;

  const ClientProjectsScreen({super.key, required this.client});

  @override
  State<ClientProjectsScreen> createState() => _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends State<ClientProjectsScreen> {
  final ProjectController _controller = ProjectController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  String _selectedStatus = 'All Projects';
  List<Project> _clientProjects = [];

  final List<String> _statusOptions = [
    'All Projects',
    'In Progress',
    'Completed',
    'On Hold',
    'Archived',
  ];

  @override
  void initState() {
    super.initState();
    _loadClientProjects();
  }

  Future<void> _loadClientProjects() async {
    await _controller.fetchProjects();
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      final all = _controller.projects.where((p) {
        if (widget.client.id != 0 && p.client?.id != null && p.client!.id != 0) {
          if (p.client!.id == widget.client.id) return true;
        }
        final clientName = widget.client.name.trim().toLowerCase();
        final pClientName = (p.client?.name ?? '').trim().toLowerCase();
        return pClientName.isNotEmpty && pClientName == clientName;
      }).toList();

      if (_selectedStatus == 'All Projects') {
        _clientProjects = all;
      } else {
        _clientProjects = all.where((p) {
          final s = p.status.toLowerCase();
          final sl = p.statusLabel.toLowerCase();
          final target = _selectedStatus.toLowerCase();
          return s == target ||
              sl == target ||
              s.replaceAll(' ', '_') == target.replaceAll(' ', '_') ||
              sl.replaceAll(' ', '_') == target.replaceAll(' ', '_');
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
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

  void _showAddProjectDialog() {
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
            side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
          ),
          title: Text(
            "Add Project",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Client: ${widget.client.name}",
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "Project Name",
                  hintStyle: TextStyle(color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                  ),
                ),
              ),
            ],
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
                    await _loadClientProjects();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _controller.errorMessage ?? "Failed to create project",
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.client.name,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadClientProjects,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with Breadcrumb & + Add Project
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.client.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    IconlyLight.document,
                                    size: 13,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Dashboard > Clients > ${widget.client.name}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                          onPressed: _showAddProjectDialog,
                          icon: const Icon(
                            IconlyLight.plus,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            "Add Project",
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

                    // Filter Card with Status Dropdown & Apply Button
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F253E) : Colors.white,
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
                                                fontWeight: e == _selectedStatus
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F2C4A),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedStatus = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D6EFD),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: _applyFilter,
                                  child: const Text(
                                    "Apply",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final count = _clientProjects.length;
                              return Text(
                                count > 0 ? "1 - $count of $count" : "0 of 0",
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

                    // Projects Table Content
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        if (_controller.isLoading && _clientProjects.isEmpty) {
                          return Column(
                            children: List.generate(
                              3,
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

                        if (_clientProjects.isEmpty) {
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
                                  "No projects have been assigned to ${widget.client.name} yet.",
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

                        // Web Admin Matching Table
                        return Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
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
                          clipBehavior: Clip.antiAlias,
                          child: Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: MediaQuery.of(context).size.width - 32,
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
                                  columnSpacing: 24,
                                  headingRowHeight: 46,
                                  dataRowMinHeight: 52,
                                  dataRowMaxHeight: 56,
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
                                    DataColumn(label: Text("OWNER")),
                                    DataColumn(label: Text("LOCATIONS")),
                                    DataColumn(label: Text("LAST ACTIVITY")),
                                  ],
                                  rows: _clientProjects.map((project) {
                                    final displayName = project.code.isNotEmpty
                                        ? '${project.name} (${project.code})'
                                        : project.name;
                                    final owner = project.ecgManager ??
                                        project.contractor?['name'] ??
                                        'Not assigned';
                                    final locations = project.siteAddress.isNotEmpty ? '1' : '1';
                                    final lastActivity = _timeAgo(project.updatedAt ?? project.createdAt);

                                    return DataRow(
                                      cells: [
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
                                              const SizedBox(width: 12),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(
                                                  maxWidth: 240,
                                                ),
                                                child: Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: textColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            owner,
                                            style: TextStyle(
                                              color: owner == 'Not assigned'
                                                  ? textSecondary
                                                  : textColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            locations,
                                            style: TextStyle(color: textColor),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            lastActivity,
                                            style: TextStyle(color: textSecondary),
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
