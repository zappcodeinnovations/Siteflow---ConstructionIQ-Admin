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
import '../../core/services/download_manager.dart';
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

  // Mirrors the web hub's own behaviour: tapping a format badge opens a
  // "choose the reporting period" dialog and downloads directly, instead of
  // navigating anywhere - matches the user's exact workflow ("jese web me
  // click karne pr filter pop up ata hai phir me use select kar ke report
  // direct downlode kar leta hu").
  void _openExportDialog({
    required String format,
    required String title,
    required String subtitle,
    required String fileNamePrefix,
    required String Function({String? from, String? to}) buildUrl,
  }) {
    final ext = format == 'excel' ? 'xlsx' : format;
    final mimeType = switch (ext) {
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'pdf' => 'application/pdf',
      _ => 'text/csv',
    };
    showDialog(
      context: context,
      builder: (_) => _ReportExportDialog(
        title: title,
        subtitle: subtitle,
        format: format,
        fileNamePrefix: fileNamePrefix,
        fileExtension: ext,
        mimeType: mimeType,
        buildUrl: buildUrl,
      ),
    );
  }

  Future<void> _downloadSpecificationsCsv() async {
    if (_selectedProjectId == null) return;
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecifications(_selectedProjectId!)}?export=csv';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading report...'), duration: Duration(seconds: 2)),
    );
    try {
      await DownloadManager.instance.downloadUrl(
        url: url,
        fileName: 'specifications_report_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
    }
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
        onFormatTap: (format) => _openExportDialog(
          format: format,
          title: 'Activity Logs',
          subtitle: 'Choose the reporting period for this export.',
          fileNamePrefix: 'activity_logs',
          buildUrl: ({from, to}) {
            var url = '${ApiEndpoints.baseUrl}/admin/activity-logs/export/?format=$format';
            if (from != null) url += '&from=$from';
            if (to != null) url += '&to=$to';
            return url;
          },
        ),
      ),
      _ReportLink(
        icon: IconlyLight.graph,
        title: 'Productivity Report',
        subtitle: 'Job-sheet completion and activity by member, team, and project.',
        formats: const ['EXCEL'],
        onTap: () => Navigator.pushNamed(context, '/productivity'),
        onFormatTap: (format) => _openExportDialog(
          format: format,
          title: 'Productivity Report',
          subtitle: 'Choose the reporting period for this export.',
          fileNamePrefix: 'productivity_report',
          buildUrl: ({from, to}) {
            var url = '${ApiEndpoints.baseUrl}/productivity/?export=excel';
            if (from != null) url += '&from=$from';
            if (to != null) url += '&to=$to';
            return url;
          },
        ),
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
        onFormatTap: !hasProject
            ? null
            : (format) => _openExportDialog(
                format: format,
                title: 'Job Sheets / Daily Reports',
                subtitle: 'Choose the reporting period for $projectName.',
                fileNamePrefix: 'job_sheets_report',
                buildUrl: ({from, to}) {
                  var url = '${ApiEndpoints.baseUrl}/job-sheets/?export=$format&project=$_selectedProjectId';
                  if (from != null) url += '&from=$from';
                  if (to != null) url += '&to=$to';
                  return url;
                },
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
        onFormatTap: !hasProject
            ? null
            : (format) => _openExportDialog(
                format: format,
                title: 'Attendance / Timesheets',
                subtitle: 'Choose the reporting period for $projectName.',
                fileNamePrefix: 'timesheets_report',
                buildUrl: ({from, to}) {
                  var url = '${ApiEndpoints.baseUrl}/timesheets/export/?project=$_selectedProjectId';
                  if (from != null) url += '&from=$from';
                  if (to != null) url += '&to=$to';
                  return url;
                },
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
        onFormatTap: !hasProject
            ? null
            : (format) => _openExportDialog(
                format: format,
                title: 'Project Productivity',
                subtitle: 'Choose the reporting period for $projectName.',
                fileNamePrefix: 'project_productivity_report',
                buildUrl: ({from, to}) {
                  // /productivity/'s `project` filter text-matches the
                  // project's name, not its id (confirmed from
                  // apply_productivity_project_filters on the backend).
                  var url = '${ApiEndpoints.baseUrl}/productivity/?export=excel&project=${Uri.encodeComponent(projectName)}';
                  if (from != null) url += '&from=$from';
                  if (to != null) url += '&to=$to';
                  return url;
                },
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
        // No period dialog on web either - Specifications downloads directly.
        onFormatTap: !hasProject ? null : (_) => _downloadSpecificationsCsv(),
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
  // When set, each format badge becomes its own tappable "export this
  // format" button (opening the period dialog), independent of the card's
  // own onTap. Null keeps the badges purely decorative, as before.
  final void Function(String format)? onFormatTap;

  _ReportLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.formats,
    required this.onTap,
    this.enabled = true,
    this.onFormatTap,
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
                              (format) {
                                final tappable = enabled && item.onFormatTap != null;
                                final chip = Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: formatBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (tappable) ...[
                                        Icon(Icons.download, size: 10, color: formatColor),
                                        const SizedBox(width: 3),
                                      ],
                                      Text(
                                        format,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: formatColor),
                                      ),
                                    ],
                                  ),
                                );
                                if (!tappable) return chip;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => item.onFormatTap!(format.toLowerCase()),
                                  child: chip,
                                );
                              },
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

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

enum _ExportPeriod { month, year, custom, all }

/// Mirrors the web hub's `#reportExportDialog`: pick a reporting period,
/// then download directly - no navigation, no intermediate screen.
class _ReportExportDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String format;
  final String fileNamePrefix;
  final String fileExtension;
  final String mimeType;
  final String Function({String? from, String? to}) buildUrl;

  const _ReportExportDialog({
    required this.title,
    required this.subtitle,
    required this.format,
    required this.fileNamePrefix,
    required this.fileExtension,
    required this.mimeType,
    required this.buildUrl,
  });

  @override
  State<_ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends State<_ReportExportDialog> {
  _ExportPeriod _period = _ExportPeriod.month;
  DateTime _monthRef = DateTime.now();
  int _year = DateTime.now().year;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _downloading = false;

  String _two(int n) => n.toString().padLeft(2, '0');
  String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  (String?, String?) _resolveRange() {
    switch (_period) {
      case _ExportPeriod.month:
        final first = DateTime(_monthRef.year, _monthRef.month, 1);
        final last = DateTime(_monthRef.year, _monthRef.month + 1, 0);
        return (_iso(first), _iso(last));
      case _ExportPeriod.year:
        return ('$_year-01-01', '$_year-12-31');
      case _ExportPeriod.custom:
        return (_customFrom != null ? _iso(_customFrom!) : null, _customTo != null ? _iso(_customTo!) : null);
      case _ExportPeriod.all:
        return (null, null);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthRef,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select any date in the month',
    );
    if (picked != null) setState(() => _monthRef = picked);
  }

  Future<void> _pickYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select any date in the year',
    );
    if (picked != null) setState(() => _year = picked.year);
  }

  Future<void> _pickCustomFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? _customTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: _customTo ?? DateTime(2101),
      helpText: 'From date',
    );
    if (picked != null) setState(() => _customFrom = picked);
  }

  Future<void> _pickCustomTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customTo ?? _customFrom ?? DateTime.now(),
      firstDate: _customFrom ?? DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'To date',
    );
    if (picked != null) setState(() => _customTo = picked);
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    final (from, to) = _resolveRange();
    final url = widget.buildUrl(from: from, to: to);
    final fileName = '${widget.fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.${widget.fileExtension}';
    try {
      final saved = await DownloadManager.instance.downloadUrl(
        url: url,
        fileName: fileName,
        mimeType: widget.mimeType,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved != null ? 'Report downloaded.' : 'Download failed.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final fieldBg = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: bg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ),
                InkWell(
                  onTap: _downloading ? null : () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Icon(Icons.close, color: subColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.subtitle, style: TextStyle(fontSize: 12.5, color: subColor)),
            const SizedBox(height: 18),
            Text('Reporting period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<_ExportPeriod>(
                  isExpanded: true,
                  value: _period,
                  dropdownColor: bg,
                  style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: _ExportPeriod.month, child: Text('Month')),
                    DropdownMenuItem(value: _ExportPeriod.year, child: Text('Year')),
                    DropdownMenuItem(value: _ExportPeriod.custom, child: Text('Custom')),
                    DropdownMenuItem(value: _ExportPeriod.all, child: Text('All')),
                  ],
                  onChanged: _downloading ? null : (v) => setState(() => _period = v ?? _ExportPeriod.month),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_period == _ExportPeriod.month)
              _PickerRow(
                label: 'Month',
                value: '${_monthNames[_monthRef.month - 1]} ${_monthRef.year}',
                onTap: _pickMonth,
                isDark: isDark,
              ),
            if (_period == _ExportPeriod.year)
              _PickerRow(label: 'Year', value: '$_year', onTap: _pickYear, isDark: isDark),
            if (_period == _ExportPeriod.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: _PickerRow(
                      label: 'From date',
                      value: _customFrom == null
                          ? 'Select date'
                          : '${_two(_customFrom!.day)}/${_two(_customFrom!.month)}/${_customFrom!.year}',
                      onTap: _pickCustomFrom,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerRow(
                      label: 'To date',
                      value: _customTo == null
                          ? 'Select date'
                          : '${_two(_customTo!.day)}/${_two(_customTo!.month)}/${_customTo!.year}',
                      onTap: _pickCustomTo,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _downloading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (_downloading ||
                            (_period == _ExportPeriod.custom && (_customFrom == null || _customTo == null)))
                        ? null
                        : _download,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.corporateBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: _downloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 16),
                    label: Text('Download ${widget.format.toUpperCase()}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  const _PickerRow({required this.label, required this.value, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final labelColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: labelColor),
          ],
        ),
      ),
    );
  }
}
