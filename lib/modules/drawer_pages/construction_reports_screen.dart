import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/services/auth_service.dart';
import '../../models/project_model.dart';
import '../projects/tabs/specifications_tab.dart';
import 'admin_screen.dart';
import 'job_sheet_screen.dart';
import 'timesheet_screen.dart';
import 'productivity_detail_screen.dart';

/// A consolidated index of reports that already exist elsewhere in the app,
/// mirroring the web "Construction Reports" hub's own two sections:
/// org-wide reports (no project needed) and project reports (disabled until
/// a project is picked from the dropdown below).
class ConstructionReportsScreen extends StatefulWidget {
  const ConstructionReportsScreen({super.key});

  @override
  State<ConstructionReportsScreen> createState() => _ConstructionReportsScreenState();
}

class _ConstructionReportsScreenState extends State<ConstructionReportsScreen> {
  List<Project> _projects = [];
  bool _loadingProjects = true;
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projects);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        if (mounted) {
          setState(() => _projects = list.map((json) => Project.fromJson(json)).toList());
        }
      }
    } catch (e) {
      debugPrint('Error fetching projects for Construction Reports: $e');
    } finally {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Project? get _selectedProject {
    if (_selectedProjectId == null) return null;
    for (final p in _projects) {
      if (p.id == _selectedProjectId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasProject = _selectedProjectId != null;
    final projectName = _selectedProject?.name ?? '';

    final orgItems = <_ReportLink>[
      _ReportLink(
        icon: IconlyLight.activity,
        title: 'Activity Logs',
        subtitle: 'Full audit trail of who changed what, across every module.',
        formats: const ['CSV', 'EXCEL', 'PDF'],
        onTap: () async {
          // AdminActivityLogsView is a reusable body widget with no
          // Scaffold of its own - it must be reached through a screen that
          // supplies one (same choice the drawer itself makes between
          // these two), not pushed directly, or Material-dependent widgets
          // inside it (e.g. the filter dropdowns) crash with
          // "No Material widget found".
          final isOperativeLogViewer = await AuthService.canViewOperativeLogs();
          if (!context.mounted) return;
          if (isOperativeLogViewer) {
            Navigator.pushNamed(context, '/operativeLogs');
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminScreen(initialMenuKey: 'admin_activity_logs'),
              ),
            );
          }
        },
      ),
      _ReportLink(
        icon: IconlyLight.graph,
        title: 'Productivity Report',
        subtitle: 'Job-sheet completion and activity by member, team, and project.',
        formats: const ['EXCEL'],
        onTap: () => Navigator.pushNamed(context, '/productivity'),
      ),
      _ReportLink(
        icon: IconlyLight.document,
        title: 'Weekly Diary',
        subtitle: 'Daily diary submissions for the selected week, per project.',
        formats: const ['PDF'],
        onTap: () => Navigator.pushNamed(context, '/weeklyDiary'),
      ),
    ];

    final projectItems = <_ReportLink>[
      _ReportLink(
        icon: IconlyLight.calendar,
        title: 'Job Sheets / Daily Reports',
        subtitle: hasProject
            ? 'Per-project job sheet records for $projectName.'
            : 'Select a project above to view its job sheet records.',
        formats: const ['EXCEL', 'PDF'],
        enabled: hasProject,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobSheetScreen(initialProjectId: _selectedProjectId),
          ),
        ),
      ),
      _ReportLink(
        icon: IconlyLight.time_circle,
        title: 'Attendance / Timesheets',
        subtitle: hasProject
            ? 'Clock-in/out history and attendance summaries for $projectName.'
            : 'Select a project above to view its attendance history.',
        formats: const ['EXCEL'],
        enabled: hasProject,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TimesheetScreen(initialProjectId: _selectedProjectId),
          ),
        ),
      ),
      _ReportLink(
        icon: IconlyLight.graph,
        title: 'Project Productivity',
        subtitle: hasProject
            ? 'Productivity breakdown by member and team for $projectName.'
            : 'Select a project above to view its productivity breakdown.',
        formats: const ['EXCEL'],
        enabled: hasProject,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductivityDetailScreen(
              id: _selectedProjectId!,
              title: projectName.isNotEmpty ? projectName : 'Project',
              isMember: false,
            ),
          ),
        ),
      ),
      _ReportLink(
        icon: Icons.description_outlined,
        title: 'Specifications',
        subtitle: hasProject
            ? 'Specification list and pricing for $projectName.'
            : 'Select a project above to view its specifications.',
        formats: const ['CSV'],
        enabled: hasProject,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text('Specifications - $projectName'),
              ),
              body: SpecificationsTab(projectId: _selectedProjectId!),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const AppNavLeading(),
        leadingWidth: AppNavigation.backAndMenuLeadingWidth,
        title: const Text(
          'Construction Reports',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark)),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(icon: Icons.public, title: 'Organisation-wide Reports', isDark: isDark),
              const SizedBox(height: 12),
              for (final item in orgItems) ...[
                _ReportCard(item: item, isDark: isDark),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              _SectionHeader(icon: Icons.folder_copy_outlined, title: 'Project Reports', isDark: isDark),
              const SizedBox(height: 12),
              _ProjectPicker(
                isDark: isDark,
                loading: _loadingProjects,
                projects: _projects,
                selectedProjectId: _selectedProjectId,
                onChanged: (id) => setState(() => _selectedProjectId = id),
              ),
              const SizedBox(height: 12),
              for (final item in projectItems) ...[
                _ReportCard(item: item, isDark: isDark),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  const _SectionHeader({required this.icon, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : const Color(0xFF0F2C4A);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.corporateBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
        ),
      ],
    );
  }
}

class _ProjectPicker extends StatelessWidget {
  final bool isDark;
  final bool loading;
  final List<Project> projects;
  final int? selectedProjectId;
  final ValueChanged<int?> onChanged;

  const _ProjectPicker({
    required this.isDark,
    required this.loading,
    required this.projects,
    required this.selectedProjectId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB);
    final labelColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 18, color: AppTheme.corporateBlue),
          const SizedBox(width: 10),
          Expanded(
            child: loading
                ? Text('Loading projects...', style: TextStyle(color: labelColor, fontSize: 13))
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedProjectId,
                      hint: Text('Select a project', style: TextStyle(color: labelColor, fontSize: 13.5)),
                      style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                      dropdownColor: cardColor,
                      items: projects
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text('${p.name} (${p.code})', overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: onChanged,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportLink {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> formats;
  final VoidCallback onTap;
  final bool enabled;

  _ReportLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.formats,
    required this.onTap,
    this.enabled = true,
  });
}

class _ReportCard extends StatelessWidget {
  final _ReportLink item;
  final bool isDark;
  const _ReportCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB);
    final titleColor = enabled
        ? (isDark ? Colors.white : const Color(0xFF0F2C4A))
        : (isDark ? Colors.white38 : const Color(0xFF9CA3AF));
    final subtitleColor = enabled
        ? (isDark ? Colors.white60 : const Color(0xFF6B7280))
        : (isDark ? Colors.white30 : const Color(0xFFB0B6BE));
    final formatBg = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);
    final formatColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final chevronColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    final iconBg = enabled
        ? AppTheme.corporateBlue.withValues(alpha: isDark ? 0.16 : 0.08)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6));
    final iconColor = enabled ? AppTheme.corporateBlue : (isDark ? Colors.white30 : const Color(0xFFB0B6BE));

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? item.onTap : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(fontSize: 12.5, color: subtitleColor),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: item.formats
                            .map(
                              (format) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: formatBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  format,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: formatColor),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled ? Icons.chevron_right : Icons.lock_outline,
                  size: enabled ? 24 : 18,
                  color: chevronColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
