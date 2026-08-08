import 'dart:convert';
import 'package:euroside_admin/core/widgets/shimmer_loading.dart';
import 'package:euroside_admin/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/widgets/status_chip.dart';
import 'project_controller.dart';
import 'project_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_endpoints.dart';

import '../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.fetchProjects().then((_) {
      if (widget.filterClient != null) {
        _controller.filterByClient(widget.filterClient!);
      }
    });
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Create Project",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2C4A),
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Project Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Delete Projects",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete ${_controller.selectedProjectIds.length} selected project(s)?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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

  String _timeAgo(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays > 0) {
        return '${diff.inDays} days, ${diff.inHours % 24} hours ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} hours, ${diff.inMinutes % 60} minutes ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTimeStr.split('T').first;
    }
  }

  String _selectedStatusTab = "All";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Custom Palette based on theme mode
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
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
                        // Search & Filter Settings Row
                        _buildSearchAndSettingsRow(isDark, borderColor, cardColor),
                        const SizedBox(height: 16),
                        
                        // Status Categories Tabs
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
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search projects...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
            onPressed: () {
              // Custom dialog / filter trigger
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs(bool isDark, Color borderColor, Color cardColor) {
    final List<String> statusTabs = ["All", "In Progress", "Completed", "On Hold", "Draft"];
    
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
          return const ShimmerLoadingList();
        }

        if (_controller.errorMessage != null && _controller.filteredProjects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        // Apply local status tab filter
        final filteredList = _controller.filteredProjects.where((p) {
          if (_selectedStatusTab == "All") return true;
          final status = (p.statusLabel.isEmpty ? "Active" : p.statusLabel).toLowerCase();
          final tabLower = _selectedStatusTab.toLowerCase();
          
          if (tabLower == "in progress" && status == "active") return true;
          return status == tabLower;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("No projects found under this status.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return ListView.separated(
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
            final priority = project.priority ?? '';
            final hasQr = project.qrToken != null || project.qrPayload != null;

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
              startDate: _timeAgo(project.createdAt),
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
              onViewQr: hasQr ? () => _showQrCode(context, project) : null,
            );
          },
        );
      },
    );
  }

  void _showQrCode(BuildContext context, Project project) {
    if (project.qrPayload == null && project.qrToken == null) return;
    
    // Use the exact payload from the backend. 
    // We generate the image locally because the backend provides data (JSON), not an image file.
    final qrData = project.qrPayload != null 
        ? jsonEncode(project.qrPayload) 
        : project.qrToken!;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
        final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
        final borderColor = isDark ? const Color(0xFF2C3E50) : Colors.grey.shade200;

        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Project QR Code",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, // Keep QR code background white for scannability
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              ),
              Text(
                project.code,
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: secondaryTextColor)),
            ),
          ],
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
    required String startDate,
    required bool isSelected,
    required ValueChanged<bool?> onSelectChanged,
    required VoidCallback onTap,
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
      priorityBg = priorityColor.withOpacity(0.15);
    }

    // Status badge styles matching mockup
    Color statusColor = Colors.green;
    Color statusBg = Colors.green.withOpacity(0.1);
    if (statusLabel.toLowerCase() == 'completed') {
      statusColor = const Color(0xFF0D6EFD);
      statusBg = const Color(0xFF0D6EFD).withOpacity(0.1);
    } else if (statusLabel.toLowerCase() == 'on hold' || statusLabel.toLowerCase() == 'draft') {
      statusColor = Colors.orange.shade800;
      statusBg = Colors.orange.shade50;
    }
    if (isDark && (statusLabel.toLowerCase() == 'on hold' || statusLabel.toLowerCase() == 'draft')) {
      statusBg = Colors.orange.withOpacity(0.15);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                        color: const Color(0xFF0D6EFD).withOpacity(0.1),
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
                              clientName,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 1, color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade100, thickness: 1),
                      const SizedBox(width: 16),
                      
                      // Budget
                      Expanded(
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
                              budget,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(width: 1, color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade100, thickness: 1),
                      const SizedBox(width: 16),

                      // Priority
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Priority",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
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

                // Bottom Row 1: Date
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      "Created: $startDate",
                      style: TextStyle(fontSize: 12, color: secondaryTextColor, fontFamily: 'Inter'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Bottom Row 2: Actions
                Row(
                  children: [
                    if (onViewQr != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF0D6EFD).withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: onViewQr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 16),
                              const SizedBox(width: 6),
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
                            color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF0D6EFD).withOpacity(0.4),
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
                            Text(
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

