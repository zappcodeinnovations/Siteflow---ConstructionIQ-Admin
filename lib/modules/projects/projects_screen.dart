import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:euroside_admin/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'project_controller.dart';
import 'project_details_screen.dart';
import '../drawer_pages/admin_team_controller.dart';
import '../drawer_pages/admin/admin_members_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../models/client_model.dart';

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
  bool _isSearchVisible = false;

  void toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  Client? _selectedClient;
  String _selectedStatusTab = "All Projects";

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.filterClient;
    _verticalScrollController.addListener(_loadMoreProjectsWhenNeeded);
    _controller.fetchAvailableClients();
    _controller.fetchProjects().then((_) {
      if (widget.filterClient != null) {
        _controller.filterByClient(widget.filterClient!);
      }
    });
  }

  void _loadMoreProjectsWhenNeeded() {
    if (_verticalScrollController.position.extentAfter < 400) {
      _controller.loadMoreProjects();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final newClientController = TextEditingController();
    int? selectedClientId = widget.filterClient?.id;
    bool isCreatingNewClient = false;
    String selectedPriority = 'medium';

    // Pre-fetch clients if not already loaded
    if (_controller.availableClients.isEmpty) {
      _controller.fetchAvailableClients();
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dialogBg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
            final titleColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final textColor = isDark ? Colors.white : Colors.black87;
            final hintColor = isDark ? Colors.white54 : Colors.grey;
            final inputBorderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
            final inputFillColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent;

            final clients = _controller.availableClients;

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark ? const BorderSide(color: AppTheme.darkBorder) : BorderSide.none,
              ),
              title: Text(
                "Create Project",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: titleColor,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name
                      Text(
                        "Project Name *",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Enter project name",
                          hintStyle: TextStyle(color: hintColor, fontSize: 14),
                          filled: true,
                          fillColor: inputFillColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: inputBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: inputBorderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Client Header & Switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Client *",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isCreatingNewClient = !isCreatingNewClient;
                                if (isCreatingNewClient) {
                                  selectedClientId = null;
                                }
                              });
                            },
                            child: Text(
                              isCreatingNewClient ? "Select Existing" : "+ New Client",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D6EFD),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (isCreatingNewClient)
                        TextField(
                          controller: newClientController,
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Enter new client name",
                            hintStyle: TextStyle(color: hintColor, fontSize: 14),
                            filled: true,
                            fillColor: inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: inputFillColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: inputBorderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: selectedClientId,
                              dropdownColor: dialogBg,
                              hint: Text("Select a client", style: TextStyle(color: hintColor, fontSize: 14)),
                              icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                              items: clients.map((client) {
                                return DropdownMenuItem<int>(
                                  value: client.id,
                                  child: Text(
                                    client.name,
                                    style: TextStyle(color: textColor, fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedClientId = val;
                                });
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Priority Selection
                      Text(
                        "Priority",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: inputBorderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedPriority,
                            dropdownColor: dialogBg,
                            icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('Low')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'high', child: Text('High')),
                              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedPriority = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
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
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a project name")),
                      );
                      return;
                    }

                    if (!isCreatingNewClient && selectedClientId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a client or click '+ New Client'")),
                      );
                      return;
                    }

                    if (isCreatingNewClient && newClientController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter the new client name")),
                      );
                      return;
                    }

                    final success = await _controller.createProject(
                      name,
                      clientId: selectedClientId,
                      newClientName: isCreatingNewClient ? newClientController.text.trim() : null,
                      priority: selectedPriority,
                    );

                    if (success && context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Project created successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _controller.errorMessage ?? "Failed to create project",
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Create",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
        final textColor = isDark ? Colors.white70 : Colors.black87;

        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark ? const BorderSide(color: AppTheme.darkBorder) : BorderSide.none,
          ),
          title: Text(
            "Delete Projects",
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
          ),
          content: Text(
            "Are you sure you want to delete ${_controller.selectedProjectIds.length} selected project(s)?",
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final success = await _controller.deleteSelectedProjects();
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Projects deleted successfully"),
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _controller.errorMessage ?? "Failed to delete projects",
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportProjectsReport() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Downloading report..."),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final allProjects = _controller.filteredProjects.isNotEmpty
          ? _controller.filteredProjects
          : _controller.projects;

      final projects = allProjects.where((p) {
        // Status Filter
        final status = (p.statusLabel.isEmpty ? p.status : p.statusLabel).toLowerCase();
        if (_selectedStatusTab == "Active Projects") {
          if (status == 'archived') return false;
        } else if (_selectedStatusTab == "Archived Projects") {
          if (status != 'archived') return false;
        }

        // Client Filter
        if (_selectedClient != null) {
          final pClientId = p.client?.id;
          final pClientName = (p.client?.name ?? '').trim().toLowerCase();
          final selClientId = _selectedClient!.id;
          final selClientName = _selectedClient!.name.trim().toLowerCase();

          if (selClientId > 0 && pClientId != null && pClientId > 0) {
            if (pClientId != selClientId) return false;
          } else {
            if (pClientName != selClientName) return false;
          }
        }

        return true;
      }).toList();

      final buffer = StringBuffer();
      buffer.writeln('Code,Name,Client,Status,Priority,Progress,Created Date');

      for (final project in projects) {
        final code = project.code;
        final escapedName = project.name.contains(',') || project.name.contains('"')
            ? '"${project.name.replaceAll('"', '""')}"'
            : project.name;
        final clientName = project.client?.name ?? '-';
        final escapedClient = clientName.contains(',') || clientName.contains('"')
            ? '"${clientName.replaceAll('"', '""')}"'
            : clientName;
        final status = project.statusLabel.isNotEmpty
            ? project.statusLabel
            : (project.status.isNotEmpty ? project.status : 'Active');
        final priority = project.priorityLabel.isNotEmpty
            ? project.priorityLabel
            : (project.priority.isNotEmpty ? project.priority : 'Normal');
        final progress = '${project.progress}%';

        String formattedDate = '';
        if (project.createdAt != null && project.createdAt!.isNotEmpty) {
          try {
            final dt = DateTime.parse(project.createdAt!);
            formattedDate =
                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
          } catch (_) {
            formattedDate = project.createdAt!;
          }
        } else {
          final now = DateTime.now();
          formattedDate =
              "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
        }

        buffer.writeln(
          '$code,$escapedName,$escapedClient,$status,$priority,$progress,$formattedDate',
        );
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/projects.csv');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Trigger the system share/save sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Projects Report CSV',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Custom Palette based on theme mode
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade200;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Background Decorative Stripes (Strip in background)
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Action Row (Export CSV & Create Project)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _exportProjectsReport,
                              icon: Icon(
                                IconlyLight.download,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              tooltip: "Export as CSV",
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _showCreateProjectDialog,
                              icon: const Icon(
                                IconlyLight.plus,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                "Create Project",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search & Filter Settings Row
                        _buildSearchAndSettingsRow(isDark, borderColor, cardColor),
                        if (_isSearchVisible) const SizedBox(height: 16),

                        // Client Filter Selector
                        _buildClientFilterDropdown(isDark, borderColor, cardColor, primaryTextColor),
                        const SizedBox(height: 14),
                        
                        // Status Categories Tabs (All Projects, Active Projects, Archived Projects)
                        _buildStatusTabs(isDark, borderColor, cardColor),
                        const SizedBox(height: 20),

                        // Project List Header/Selected count
                        _buildListHeader(secondaryTextColor),
                        const SizedBox(height: 12),

                        // List of Project Cards
                        _buildProjectsList(isDark, cardColor, borderColor, primaryTextColor, secondaryTextColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientFilterDropdown(bool isDark, Color borderColor, Color cardColor, Color primaryTextColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final clients = _controller.availableClients;
        return Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: _selectedClient?.id,
              dropdownColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.grey.shade700),
              hint: Row(
                children: [
                  Icon(Icons.business_outlined, size: 18, color: const Color(0xFF0D6EFD)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedClient?.name ?? "All Clients",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Text(
                        "All Clients",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedClient == null ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ...clients.map((client) {
                  return DropdownMenuItem<int?>(
                    value: client.id,
                    child: Text(
                      client.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedClient?.id == client.id ? FontWeight.bold : FontWeight.normal,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (clientId) {
                setState(() {
                  if (clientId == null) {
                    _selectedClient = null;
                  } else {
                    _selectedClient = clients.firstWhere(
                      (c) => c.id == clientId,
                      orElse: () => Client(id: clientId, name: 'Client'),
                    );
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndSettingsRow(bool isDark, Color borderColor, Color cardColor) {
    if (!_isSearchVisible) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => _controller.searchProjects(value),
              onChanged: (value) {
                _controller.searchProjects(value);
                setState(() {});
              },
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search projects...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _controller.searchProjects('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Reset Filter Button
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: IconButton(
            icon: Icon(
              Icons.restart_alt,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              size: 20,
            ),
            tooltip: "Reset Filters",
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedStatusTab = "All Projects";
                _selectedClient = null;
              });
              _controller.searchProjects('');
              _controller.fetchProjects();
              _controller.fetchAvailableClients();
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600, size: 20),
            tooltip: "Filter",
            onPressed: () {
              // Custom dialog / filter trigger
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(bool isDark, Color borderColor, Color cardColor) {
    final List<String> statusTabs = ["All Projects", "Active Projects", "Archived Projects"];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statusTabs.map((tab) {
          final isSelected = _selectedStatusTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatusTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D6EFD) : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D6EFD) : borderColor,
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListHeader(Color textColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.selectedProjectIds.isEmpty) {
          return const SizedBox.shrink();
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${_controller.selectedProjectIds.length} projects selected",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: _confirmDeleteSelected,
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
              label: const Text("Delete Selected", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            )
          ],
        );
      },
    );
  }

  Widget _buildProjectsList(bool isDark, Color cardColor, Color borderColor, Color primaryTextColor, Color secondaryTextColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isLoading && _controller.filteredProjects.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_controller.errorMessage != null && _controller.filteredProjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        // Apply status and client filter
        final filteredList = _controller.filteredProjects.where((p) {
          // Status filter
          final status = (p.statusLabel.isEmpty ? p.status : p.statusLabel).toLowerCase();
          if (_selectedStatusTab == "Active Projects") {
            if (status == 'archived') return false;
          } else if (_selectedStatusTab == "Archived Projects") {
            if (status != 'archived') return false;
          }

          // Client filter
          if (_selectedClient != null) {
            final pClientId = p.client?.id;
            final pClientName = (p.client?.name ?? '').trim().toLowerCase();
            final selClientId = _selectedClient!.id;
            final selClientName = _selectedClient!.name.trim().toLowerCase();

            if (selClientId > 0 && pClientId != null && pClientId > 0) {
              if (pClientId != selClientId) return false;
            } else {
              if (pClientName != selClientName) return false;
            }
          }

          return true;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("No projects found matching the selected filters.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
            final project = filteredList[index];
            final isSelected = _controller.selectedProjectIds.contains(project.id);
            
            // Format labels
            final projectCode = project.code.isNotEmpty ? project.code : 'PROJ-${project.id}';
            final projectName = project.name;
            final clientName = project.client?.name ?? 'N/A';
            final statusLabel = project.statusLabel.isNotEmpty ? project.statusLabel : "In Progress";
            final budget = project.budget != null ? "£${project.budget}" : '';
            final priority = project.priority;
            return _buildProjectCardItem(
              context,
              isDark: isDark,
              cardColor: cardColor,
              borderColor: isSelected ? const Color(0xFF0D6EFD) : borderColor,
              borderWidth: isSelected ? 2.0 : 1.0,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              projectCode: projectCode,
              projectName: projectName,
              clientName: clientName,
              statusLabel: statusLabel,
              budget: budget,
              priority: priority,
              lastActivity: project.displayActivity,
              isSelected: isSelected,
              onSelectChanged: (val) {
                _controller.toggleSelection(project.id);
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProjectDetailsScreen(project: project),
                  ),
                );
              },
              onAssignTeam: () => _showAssignTeamDialog(context, project),
              onViewTeam: () => _showViewTeamDialog(context, project),
              onViewQr: () => _showQrCode(context, project),
            );
              },
            ),
            if (_controller.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_controller.hasMore)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Scroll to load more projects', style: TextStyle(color: secondaryTextColor)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _downloadQrCode(BuildContext context, String qrData, Project project) async {
    try {
      final painter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (picData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to generate QR image")),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final sanitizedCode = (project.code.isNotEmpty ? project.code : 'PROJ_${project.id}')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final file = File('${tempDir.path}/QR_$sanitizedCode.png');
      await file.writeAsBytes(picData.buffer.asUint8List());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("QR Code exported ($sanitizedCode.png)"),
          ),
        );
      }

      await Share.shareXFiles([XFile(file.path)], text: 'Project QR Code: ${project.name} ($sanitizedCode)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving QR Code: $e")),
        );
      }
    }
  }

  void _showQrCode(BuildContext context, Project project) {
    String qrData = '';
    if (project.qrPayload != null && project.qrPayload!.isNotEmpty) {
      try {
        qrData = jsonEncode(project.qrPayload);
      } catch (_) {
        qrData = project.qrPayload.toString();
      }
    } else if (project.qrToken != null && project.qrToken!.trim().isNotEmpty) {
      qrData = project.qrToken!.trim();
    } else {
      qrData = jsonEncode({
        "project_id": project.id,
        "project_code": project.code.isNotEmpty ? project.code : "PROJ-${project.id}",
        "project_name": project.name,
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final bgColor = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
        final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Title and Dismiss Cross (x) Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        "Project QR Code",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      color: textColor.withValues(alpha: 0.7),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // QR Code Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      backgroundColor: Colors.white,
                    ),
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
                  project.code.isNotEmpty ? project.code : 'PROJ-${project.id}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Bottom Actions: Close and Download QR
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _downloadQrCode(context, qrData, project);
                        },
                        icon: const Icon(IconlyLight.download, size: 18),
                        label: const Text(
                          "Download QR",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
  }

  void _showViewTeamDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _controller.fetchAssignments(project.id),
          builder: (context, snapshot) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dialogBg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final secondaryTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
            final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
            final itemBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC);

            Widget bodyContent;

            if (snapshot.connectionState == ConnectionState.waiting) {
              bodyContent = const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError || snapshot.data == null) {
              bodyContent = Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(IconlyLight.danger, size: 40, color: Colors.orange.shade400),
                    const SizedBox(height: 12),
                    Text(
                      "No assignments found",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "No team or workers assigned to this project yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                  ],
                ),
              );
            } else {
              final data = snapshot.data!;
              final rawTeams = data['teams'] ?? data['assigned_teams'] ?? [];
              final rawWorkers = data['workers'] ?? data['assigned_workers'] ?? data['members'] ?? [];

              final List<dynamic> teams = rawTeams is List ? rawTeams : [];
              final List<dynamic> workers = rawWorkers is List ? rawWorkers : [];

              final hasNoAssignments = teams.isEmpty && workers.isEmpty;

              if (hasNoAssignments) {
                bodyContent = Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      Icon(IconlyLight.user_1, size: 44, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        "No Team Assigned",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "This project currently has no assigned teams or operatives.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: secondaryTextColor),
                      ),
                    ],
                  ),
                );
              } else {
                bodyContent = ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (teams.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.group_outlined, size: 16, color: Color(0xFF0D6EFD)),
                              const SizedBox(width: 6),
                              Text(
                                "Assigned Teams (${teams.length})",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...teams.map((teamItem) {
                            final String teamName = teamItem is Map
                                ? (teamItem['name'] ?? teamItem['display_name'] ?? 'Team #${teamItem['id'] ?? ''}')
                                : 'Team #$teamItem';
                            final String? leadName = teamItem is Map ? teamItem['lead_name'] : null;
                            final int? memberCount = teamItem is Map ? teamItem['member_count'] : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.group_outlined, size: 18, color: Color(0xFF0D6EFD)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          teamName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        if (leadName != null && leadName.isNotEmpty)
                                          Text(
                                            "Lead: $leadName",
                                            style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (memberCount != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "$memberCount members",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D6EFD),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                        if (workers.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(IconlyLight.user_1, size: 16, color: Color(0xFF0D6EFD)),
                              const SizedBox(width: 6),
                              Text(
                                "Assigned Operatives / Members (${workers.length})",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...workers.map((workerItem) {
                            final String name = workerItem is Map
                                ? (workerItem['display_name'] ??
                                    '${workerItem['first_name'] ?? ''} ${workerItem['last_name'] ?? ''}'.trim().isNotEmpty
                                        ? '${workerItem['first_name'] ?? ''} ${workerItem['last_name'] ?? ''}'.trim()
                                        : workerItem['name'] ?? workerItem['email'] ?? 'Member #${workerItem['id'] ?? ''}')
                                : 'Member #$workerItem';
                            final String? role = workerItem is Map ? (workerItem['role_display_name'] ?? workerItem['role']) : null;
                            final String? email = workerItem is Map ? workerItem['email'] : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF0D6EFD).withValues(alpha: 0.15),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF0D6EFD),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        if (role != null && role.isNotEmpty)
                                          Text(
                                            role,
                                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                          )
                                        else if (email != null && email.isNotEmpty)
                                          Text(
                                            email,
                                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }
            }

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark ? const BorderSide(color: AppTheme.darkBorder) : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Project Team",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${project.code.isNotEmpty ? '${project.code} • ' : ''}${project.name}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          color: textColor.withValues(alpha: 0.7),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    bodyContent,
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _showAssignTeamDialog(context, project);
                            },
                            icon: const Icon(IconlyLight.user_1, size: 16),
                            label: const Text(
                              "Assign / Edit",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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

  void _showAssignTeamDialog(BuildContext context, Project project) {
    final teamController = AdminTeamController();
    final membersController = AdminMembersController();
    final searchWorkerController = TextEditingController();

    bool isLoadingData = true;
    bool isSaving = false;
    String? errorMessage;
    String searchWorkerQuery = '';

    final List<int> selectedTeamIds = [];
    final List<int> selectedWorkerIds = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dialogBg = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final secondaryTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
            final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
            final itemBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC);

            // Fetch initial data once
            if (isLoadingData && errorMessage == null) {
              Future.wait([
                _controller.fetchAssignments(project.id),
                teamController.fetchTeams(),
                membersController.fetchMembers(),
              ]).then((results) {
                final assignmentData = results[0] as Map<String, dynamic>?;
                if (assignmentData != null) {
                  final rawTeams = assignmentData['teams'] ?? assignmentData['assigned_teams'] ?? [];
                  final rawWorkers = assignmentData['workers'] ?? assignmentData['assigned_workers'] ?? assignmentData['members'] ?? [];

                  if (rawTeams is List) {
                    for (var t in rawTeams) {
                      if (t is int) {
                        selectedTeamIds.add(t);
                      } else if (t is Map && t['id'] != null) {
                        final id = int.tryParse(t['id'].toString());
                        if (id != null) selectedTeamIds.add(id);
                      }
                    }
                  }
                  if (rawWorkers is List) {
                    for (var w in rawWorkers) {
                      if (w is int) {
                        selectedWorkerIds.add(w);
                      } else if (w is Map && w['id'] != null) {
                        final id = int.tryParse(w['id'].toString());
                        if (id != null) selectedWorkerIds.add(id);
                      }
                    }
                  }
                }
                setDialogState(() {
                  isLoadingData = false;
                });
              }).catchError((e) {
                setDialogState(() {
                  isLoadingData = false;
                  errorMessage = 'Failed to load team data: $e';
                });
              });
            }

            final teams = teamController.teams;
            final allMembers = membersController.members;
            final filteredMembers = allMembers.where((m) {
              if (searchWorkerQuery.isEmpty) return true;
              final query = searchWorkerQuery.toLowerCase();
              return m.displayName.toLowerCase().contains(query) ||
                  m.email.toLowerCase().contains(query) ||
                  m.roleDisplayName.toLowerCase().contains(query) ||
                  m.role.toLowerCase().contains(query);
            }).toList();

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark ? const BorderSide(color: AppTheme.darkBorder) : BorderSide.none,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: 500,
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Assign Team",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${project.code.isNotEmpty ? '${project.code} • ' : ''}${project.name}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          color: textColor.withValues(alpha: 0.7),
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isLoadingData) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ] else if (errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                            const SizedBox(height: 8),
                            Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TEAMS SECTION
                              Row(
                                children: [
                                  const Icon(Icons.group_outlined, size: 16, color: Color(0xFF0D6EFD)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Teams",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "(${selectedTeamIds.length} selected)",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0D6EFD),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (teams.isEmpty)
                                Text(
                                  "No teams configured yet.",
                                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: teams.map((team) {
                                    final isSelected = selectedTeamIds.contains(team.id);
                                    return FilterChip(
                                      selected: isSelected,
                                      showCheckmark: true,
                                      checkmarkColor: Colors.white,
                                      avatar: !isSelected ? const Icon(Icons.group_outlined, size: 14) : null,
                                      label: Text(
                                        "${team.name} (${team.memberCount})",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : textColor,
                                        ),
                                      ),
                                      selectedColor: const Color(0xFF0D6EFD),
                                      backgroundColor: itemBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF0D6EFD) : borderColor,
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        setDialogState(() {
                                          if (selected) {
                                            selectedTeamIds.add(team.id);
                                          } else {
                                            selectedTeamIds.remove(team.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 20),

                              // OPERATIVES / MEMBERS SECTION
                              Row(
                                children: [
                                  const Icon(IconlyLight.user_1, size: 16, color: Color(0xFF0D6EFD)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Operatives / Members",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "(${selectedWorkerIds.length} selected)",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0D6EFD),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Search input for workers
                              TextField(
                                controller: searchWorkerController,
                                onChanged: (val) {
                                  setDialogState(() {
                                    searchWorkerQuery = val;
                                  });
                                },
                                style: TextStyle(color: textColor, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Search operatives by name, role or email...",
                                  hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                                  prefixIcon: Icon(Icons.search, size: 18, color: secondaryTextColor),
                                  suffixIcon: searchWorkerQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: () {
                                            searchWorkerController.clear();
                                            setDialogState(() {
                                              searchWorkerQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  filled: true,
                                  fillColor: itemBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (allMembers.isEmpty)
                                Text(
                                  "No operatives found.",
                                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                )
                              else if (filteredMembers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      "No operatives match '$searchWorkerQuery'",
                                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 220),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filteredMembers.length,
                                    separatorBuilder: (c, i) => Divider(height: 1, color: borderColor),
                                    itemBuilder: (context, index) {
                                      final member = filteredMembers[index];
                                      final isSelected = selectedWorkerIds.contains(member.id);

                                      return InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            if (isSelected) {
                                              selectedWorkerIds.remove(member.id);
                                            } else {
                                              selectedWorkerIds.add(member.id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: isSelected,
                                                activeColor: const Color(0xFF0D6EFD),
                                                onChanged: (val) {
                                                  setDialogState(() {
                                                    if (val == true) {
                                                      selectedWorkerIds.add(member.id);
                                                    } else {
                                                      selectedWorkerIds.remove(member.id);
                                                    }
                                                  });
                                                },
                                              ),
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                                                child: Text(
                                                  member.displayName.isNotEmpty
                                                      ? member.displayName[0].toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0D6EFD),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      member.displayName,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      member.roleDisplayName.isNotEmpty
                                                          ? member.roleDisplayName
                                                          : member.email,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: secondaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isSaving = true;
                                      });
                                      final success = await _controller.assignProject(
                                        project.id,
                                        teamIds: selectedTeamIds,
                                        workerIds: selectedWorkerIds,
                                      );
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? "Team assignments updated successfully."
                                                  : (_controller.errorMessage ?? "Failed to update assignments."),
                                            ),
                                            backgroundColor: success ? Colors.green : Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Save Assignments",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectCardItem(
    BuildContext context, {
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required double borderWidth,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required String projectCode,
    required String projectName,
    required String clientName,
    required String statusLabel,
    required String budget,
    required String priority,
    required String lastActivity,
    required bool isSelected,
    required ValueChanged<bool?> onSelectChanged,
    required VoidCallback onTap,
    required VoidCallback? onAssignTeam,
    required VoidCallback? onViewTeam,
    required VoidCallback? onViewQr,
  }) {
    // Priority badge styles
    Color priorityColor = Colors.orange;
    Color priorityBg = Colors.orange.shade50;
    if (priority.toLowerCase() == 'high') {
      priorityColor = Colors.red;
      priorityBg = Colors.red.shade50;
    } else if (priority.toLowerCase() == 'low') {
      priorityColor = Colors.green;
      priorityBg = Colors.green.shade50;
    }
    if (isDark) {
      priorityBg = priorityColor.withValues(alpha: 0.15);
    }

    // Status badge styles matching mockup
    Color statusColor = Colors.green;
    Color statusBg = Colors.green.withValues(alpha: 0.1);
    if (statusLabel.toLowerCase() == 'completed') {
      statusColor = const Color(0xFF0D6EFD);
      statusBg = const Color(0xFF0D6EFD).withValues(alpha: 0.1);
    } else if (statusLabel.toLowerCase() == 'on hold' || statusLabel.toLowerCase() == 'draft') {
      statusColor = Colors.orange.shade800;
      statusBg = Colors.orange.shade50;
    }
    if (isDark && (statusLabel.toLowerCase() == 'on hold' || statusLabel.toLowerCase() == 'draft')) {
      statusBg = Colors.orange.withValues(alpha: 0.15);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => onSelectChanged(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon, Name/Code, Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: Color(0xFF0D6EFD), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectCode.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: secondaryTextColor,
                              letterSpacing: 0.5,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            projectName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Details Grid (Client, Budget, Priority) with vertical divider lines
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Client
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  "Client",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              clientName.isNotEmpty ? clientName : "-",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      VerticalDivider(width: 1, color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade100, thickness: 1),
                      const SizedBox(width: 12),
                      
                      // Budget
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  "Budget",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              budget.isNotEmpty ? budget : "-",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      VerticalDivider(width: 1, color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade100, thickness: 1),
                      const SizedBox(width: 12),

                      // Priority
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Priority",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Divider(height: 1, color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade100),
                const SizedBox(height: 16),

                // Bottom Row 1: Last Activity
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      "Last Activity: $lastActivity",
                      style: TextStyle(fontSize: 12, color: secondaryTextColor, fontFamily: 'Inter'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Team Action Buttons: Assign & View Team
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: onAssignTeam,
                        icon: const Icon(IconlyLight.user_1, size: 16),
                        label: const Text(
                          "Assign",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: onViewTeam,
                        icon: const Icon(IconlyLight.show, size: 16),
                        label: const Text(
                          "View Team",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Bottom Row 2: Project Actions (QR Code & View Details)
                Row(
                  children: [
                    if (onViewQr != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: onViewQr,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "QR Code",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onTap,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "View Details",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios, 
                              size: 12, 
                              color: isDark ? Colors.white70 : const Color(0xFF0D6EFD),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// End of ProjectsScreenState

