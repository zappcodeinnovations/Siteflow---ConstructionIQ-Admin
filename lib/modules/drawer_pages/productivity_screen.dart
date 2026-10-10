import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/custom_drawer.dart';
import 'productivity_controller.dart';
import 'productivity_detail_screen.dart';

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> {
  final ProductivityController _controller = ProductivityController();
  final TextEditingController _searchFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.fetchProductivity();
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked =
        await CustomDatePickerDialog.showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final startStr =
          "${picked.start.day.toString().padLeft(2, '0')}/${picked.start.month.toString().padLeft(2, '0')}/${picked.start.year}";
      final endStr =
          "${picked.end.day.toString().padLeft(2, '0')}/${picked.end.month.toString().padLeft(2, '0')}/${picked.end.year}";
      _controller.setDateRange(startStr, endStr);
      _controller.fetchProductivity();
    }
  }

  void _showDatePresetPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final presets = ['This Month', 'Last Month', 'This Year', 'All time', 'Custom Date Range...'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    "Select Date Range",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                    ),
                  ),
                ),
                const Divider(),
                ...presets.map((preset) {
                  final isSelected = _controller.datePreset == preset;
                  return ListTile(
                    title: Text(
                      preset,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF0D6EFD)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF0D6EFD))
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (preset == 'Custom Date Range...') {
                        _selectDateRange(context);
                      } else {
                        _controller.setDatePreset(preset);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddFilterDialog() {
    final options = _controller.data?.filterOptions ?? {};
    final clients = (options['clients'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final projects = (options['projects'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final teams = (options['teams'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final members = (options['members'] as List?)?.map((e) => e.toString()).toList() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String? tempClient = _controller.selectedClient;
        String? tempProject = _controller.selectedProject;
        String? tempTeam = _controller.selectedTeam;
        String? tempMember = _controller.selectedMember;

        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
        final fieldFill = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC);
        final fieldBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
        final labelColor = isDark ? Colors.grey.shade400 : Colors.black87;
        final itemTextColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                IconlyLight.filter,
                                color: Color(0xFF0D6EFD),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Filter Categories",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            IconlyLight.close_square,
                            color: isDark ? Colors.white70 : Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Client Filter
                    _buildModalDropdown(
                      "Client",
                      tempClient,
                      ["All Clients", ...clients],
                      (val) => setModalState(() => tempClient = val == "All Clients" ? null : val),
                      isDark,
                      fieldFill,
                      fieldBorder,
                      labelColor,
                      itemTextColor,
                    ),
                    const SizedBox(height: 14),

                    // 2. Project Filter
                    _buildModalDropdown(
                      "Project",
                      tempProject,
                      ["All Projects", ...projects],
                      (val) => setModalState(() => tempProject = val == "All Projects" ? null : val),
                      isDark,
                      fieldFill,
                      fieldBorder,
                      labelColor,
                      itemTextColor,
                    ),
                    const SizedBox(height: 14),

                    // 3. Team Filter
                    _buildModalDropdown(
                      "Team",
                      tempTeam,
                      ["All Teams", ...teams],
                      (val) => setModalState(() => tempTeam = val == "All Teams" ? null : val),
                      isDark,
                      fieldFill,
                      fieldBorder,
                      labelColor,
                      itemTextColor,
                    ),
                    const SizedBox(height: 14),

                    // 4. Member Filter
                    _buildModalDropdown(
                      "Member",
                      tempMember,
                      ["All Members", ...members],
                      (val) => setModalState(() => tempMember = val == "All Members" ? null : val),
                      isDark,
                      fieldFill,
                      fieldBorder,
                      labelColor,
                      itemTextColor,
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                              ),
                            ),
                            onPressed: () {
                              setModalState(() {
                                tempClient = null;
                                tempProject = null;
                                tempTeam = null;
                                tempMember = null;
                              });
                            },
                            child: Text(
                              "Clear All",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              _controller.setFilters(
                                client: tempClient,
                                project: tempProject,
                                team: tempTeam,
                                member: tempMember,
                              );
                              _controller.fetchProductivity();
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

  Widget _buildModalDropdown(
    String label,
    String? currentValue,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
    Color fieldFill,
    Color fieldBorder,
    Color labelColor,
    Color itemTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentValue ?? items.first,
              dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
              icon: const Icon(IconlyLight.arrow_down_2, color: Colors.grey, size: 18),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: itemTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadReport() async {
    final baseUrl = '${ApiEndpoints.baseUrl}/productivity/?export=excel';
    List<String> queryParams = [];
    if (_controller.fromDate.isNotEmpty) {
      queryParams.add('from=${_controller.fromDate}');
    }
    if (_controller.toDate.isNotEmpty) {
      queryParams.add('to=${_controller.toDate}');
    }
    if (_controller.selectedClient != null && _controller.selectedClient!.isNotEmpty) {
      queryParams.add('client=${_controller.selectedClient}');
    }
    if (_controller.selectedProject != null && _controller.selectedProject!.isNotEmpty) {
      queryParams.add('project=${_controller.selectedProject}');
    }
    if (_controller.selectedTeam != null && _controller.selectedTeam!.isNotEmpty) {
      queryParams.add('team=${_controller.selectedTeam}');
    }
    if (_controller.selectedMember != null && _controller.selectedMember!.isNotEmpty) {
      queryParams.add('member=${_controller.selectedMember}');
    }

    final finalUrl = queryParams.isEmpty ? baseUrl : '$baseUrl&${queryParams.join('&')}';

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Downloading productivity report..."),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await ApiClient.get(finalUrl);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/Productivity_Report_$timestamp.xlsx');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await Share.shareXFiles(
            [XFile(file.path)],
            text: "Productivity Report",
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to download: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error downloading report")),
        );
      }
    }
  }

  Widget _buildKpiCard(
    String title,
    String value,
    Color bgColor,
    Color textColor,
    IconData iconData,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppTheme.corporateBlue : const Color(0xFF0F2C4A);
    final cardBorder = Border.all(
      color: isDark ? Colors.white24 : const Color(0xFF1E3A8A).withValues(alpha: 0.3),
      width: 1.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(iconData, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton("By Member", "member"),
          _buildToggleButton("By Team", "team"),
          _buildToggleButton("By Project", "project"),
          _buildToggleButton("My Reports", "reports"),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String viewKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _controller.currentView == viewKey;
    return InkWell(
      onTap: () => _controller.setView(viewKey),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D6EFD)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF0F2C4A)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMyReportsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(IconlyLight.paper, color: Color(0xFF0D6EFD)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Productivity Reports",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Download custom productivity breakdowns and exports.",
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(IconlyLight.document, color: Color(0xFF0D6EFD), size: 18),
            ),
            title: Text(
              "Full Productivity Export (Excel)",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
            ),
            subtitle: Text(
              "Includes active projects, team metrics, operative hours & costs",
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _downloadReport,
              icon: const Icon(IconlyLight.download, size: 14),
              label: const Text("Export", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0FDF4),
              child: Icon(IconlyLight.chart, color: Color(0xFF15803D), size: 18),
            ),
            title: Text(
              "Member Work & Timesheet Summary",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
            ),
            subtitle: Text(
              "Scoped to ${_controller.datePreset}",
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            trailing: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D6EFD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _downloadReport,
              icon: const Icon(IconlyLight.download, size: 14, color: Color(0xFF0D6EFD)),
              label: const Text("Download", style: TextStyle(fontSize: 12, color: Color(0xFF0D6EFD), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_controller.isLoading && _controller.data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_controller.errorMessage != null && _controller.data == null) {
      return Center(
        child: Text(
          _controller.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_controller.data == null) {
      return const Center(child: Text("No productivity data."));
    }

    if (_controller.currentView == 'reports') {
      return _buildMyReportsView();
    }

    final itemCount = _getListItemCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _controller.currentView == 'member'
                    ? "Team Members"
                    : _controller.currentView == 'team'
                        ? "Teams"
                        : "Projects",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                "Showing $itemCount results",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (itemCount == 0)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                "No records found matching your filters.",
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildListCard(index),
          ),
      ],
    );
  }

  int _getListItemCount() {
    if (_controller.currentView == 'member') {
      return _controller.filteredMembers.length;
    }
    if (_controller.currentView == 'team') {
      return _controller.filteredTeams.length;
    }
    if (_controller.currentView == 'project') {
      return _controller.filteredProjects.length;
    }
    return 0;
  }

  Widget _buildListCard(int index) {
    String title = "";
    String subtitle = "";
    String initials = "";
    String badgeText = "";
    Color avatarColor = const Color(0xFF0F172A);

    String sheets = "0";
    String opCost = "£0";
    String matCost = "£0";
    String totalCharge = "£0.00";

    VoidCallback? onTap;

    if (_controller.currentView == 'member') {
      final member = _controller.filteredMembers[index];
      title = member.name;
      subtitle = "Team Member";
      initials = member.initials.isNotEmpty
          ? member.initials
          : (member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : "M");
      badgeText = member.team;
      sheets = member.jobSheets.toString();
      opCost = '£${member.operative.toStringAsFixed(0)}';
      matCost = '£${member.materialCost.toStringAsFixed(0)}';
      totalCharge = '£${member.charge.toStringAsFixed(2)}';
      avatarColor = index % 2 == 0 ? const Color(0xFF0F172A) : const Color(0xFF0D6EFD);

      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductivityDetailScreen(
                id: member.id,
                title: member.name,
                isMember: true,
              ),
            ),
          );
    } else if (_controller.currentView == 'team') {
      final team = _controller.filteredTeams[index];
      title = team.team;
      subtitle = "${team.members} Members";
      initials = team.team.isNotEmpty ? team.team.substring(0, 1).toUpperCase() : "T";
      sheets = team.jobSheets.toString();
      opCost = '£${team.operative.toStringAsFixed(0)}';
      matCost = '£${team.materialCost.toStringAsFixed(0)}';
      totalCharge = '£${team.charge.toStringAsFixed(2)}';
      avatarColor = const Color(0xFF0D9488);
    } else {
      final project = _controller.filteredProjects[index];
      title = project.name;
      subtitle = project.client;
      initials = project.name.isNotEmpty ? project.name.substring(0, 1).toUpperCase() : "P";
      badgeText = "${project.members} Members";
      sheets = project.jobSheets.toString();
      opCost = '£${project.operative.toStringAsFixed(0)}';
      matCost = '£${project.materialCost.toStringAsFixed(0)}';
      totalCharge = '£${project.charge.toStringAsFixed(2)}';
      avatarColor = const Color(0xFF7C3AED);

      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductivityDetailScreen(
                id: project.id,
                title: project.name,
                isMember: false,
              ),
            ),
          );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF4338CA),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "SHEETS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sheets,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "OP COST",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opCost,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "MAT COST",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          matCost,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade100,
              ),
              const SizedBox(height: 16),

              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Charge",
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                  Text(
                    totalCharge,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          "Productivity",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Prominent Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchFieldController,
                          onChanged: (val) => _controller.setSearchQuery(val),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search projects, teams, job sheets...",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              IconlyLight.search,
                              color: Color(0xFF0D6EFD),
                              size: 20,
                            ),
                            suffixIcon: _searchFieldController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchFieldController.clear();
                                      _controller.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. High-Contrast Date Presets & Filter Controls
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Date Preset Selector (Sharp High-Contrast Styling)
                            InkWell(
                              onTap: _showDatePresetPicker,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.corporateBlue : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white30
                                        : const Color(0xFF0F2C4A).withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      IconlyLight.calendar,
                                      size: 15,
                                      color: Color(0xFF0D6EFD),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _controller.datePreset,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F2C4A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      IconlyLight.arrow_down_2,
                                      size: 14,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // + Add Filter Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                                side: BorderSide(
                                  color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: _showAddFilterDialog,
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF0D6EFD),
                              ),
                              label: Text(
                                "+ Add Filter",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Apply Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _controller.fetchProductivity(),
                              child: const Text(
                                "Apply",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Reset Button
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Color(0xFF0D6EFD),
                              ),
                              tooltip: 'Reset Filters',
                              onPressed: () {
                                _searchFieldController.clear();
                                _controller.resetFilters();
                              },
                            ),

                            // Get Report / Export
                            IconButton(
                              icon: const Icon(
                                IconlyLight.download,
                                color: Color(0xFF0D6EFD),
                              ),
                              tooltip: 'Export Excel Report',
                              onPressed: _downloadReport,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Tab Toggles (By Member, By Team, By Project, My Reports)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildToggleBar(),
                      ),
                      const SizedBox(height: 20),

                      // 4. KPI Summary Cards Grid
                      if (_controller.data != null)
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.45,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildKpiCard(
                              "Active Projects",
                              _controller.data!.summary?.activeProjects.toString() ?? "0",
                              const Color(0xFFEEF2FF),
                              const Color(0xFF4338CA),
                              IconlyLight.chart,
                            ),
                            _buildKpiCard(
                              "Active Members",
                              _controller.data!.summary?.activeMembers.toString() ?? "0",
                              const Color(0xFFFFFBEB),
                              const Color(0xFFB45309),
                              IconlyLight.category,
                            ),
                            _buildKpiCard(
                              "Job Sheets",
                              _controller.data!.summary?.jobSheets.toString() ?? "0",
                              const Color(0xFFF0FDF4),
                              const Color(0xFF15803D),
                              IconlyLight.paper,
                            ),
                            _buildKpiCard(
                              "Operative",
                              '£${_controller.data!.summary?.operativeTotal.toStringAsFixed(2) ?? "0.00"}',
                              const Color(0xFFFAFAFA),
                              Colors.black87,
                              IconlyLight.category,
                            ),
                            _buildKpiCard(
                              "Material Cost",
                              '£${_controller.data!.summary?.materialCostTotal.toStringAsFixed(2) ?? "0.00"}',
                              const Color(0xFFFAFAFA),
                              Colors.black87,
                              IconlyLight.category,
                            ),
                            _buildKpiCard(
                              "Charge",
                              '£${_controller.data!.summary?.chargeTotal.toStringAsFixed(2) ?? "0.00"}',
                              const Color(0xFFEEF2FF),
                              const Color(0xFF2563EB),
                              IconlyLight.category,
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // 5. Dynamic Data List or My Reports Section
                      _buildDataList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}