import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/app_back_button.dart';
import 'admin/admin_activity_logs_view.dart';

/// A consolidated index of reports that already exist elsewhere in the app
/// (Activity Logs, Productivity, Job Sheets, Weekly Diary, Timesheet) -
/// deliberately not a new report screen, just one place that links to each
/// of them, mirroring the web "Construction Reports" hub.
class ConstructionReportsScreen extends StatelessWidget {
  const ConstructionReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <_ReportLink>[
      _ReportLink(
        icon: IconlyLight.activity,
        title: 'Activity Logs',
        subtitle: 'Full audit trail of who changed what, across every module.',
        formats: const ['CSV', 'EXCEL', 'PDF'],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminActivityLogsView()),
        ),
      ),
      _ReportLink(
        icon: IconlyLight.graph,
        title: 'Productivity Report',
        subtitle: 'Job-sheet completion and activity by member, team, and project.',
        formats: const ['EXCEL'],
        onTap: () => Navigator.pushNamed(context, '/productivity'),
      ),
      _ReportLink(
        icon: IconlyLight.calendar,
        title: 'Job Sheets / Daily Reports',
        subtitle: 'Per-project job sheet records, exportable from the Job Sheets screen.',
        formats: const ['EXCEL', 'PDF'],
        onTap: () => Navigator.pushNamed(context, '/jobSheet'),
      ),
      _ReportLink(
        icon: IconlyLight.document,
        title: 'Weekly Diary',
        subtitle: 'Daily diary submissions for the selected week, per project.',
        formats: const ['PDF'],
        onTap: () => Navigator.pushNamed(context, '/weeklyDiary'),
      ),
      _ReportLink(
        icon: IconlyLight.time_circle,
        title: 'Attendance / Timesheets',
        subtitle: 'Clock-in/out history and attendance summaries.',
        formats: const ['EXCEL'],
        onTap: () => Navigator.pushNamed(context, '/timesheet'),
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
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ReportCard(item: items[index]),
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

  _ReportLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.formats,
    required this.onTap,
  });
}

class _ReportCard extends StatelessWidget {
  final _ReportLink item;
  const _ReportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.corporateBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppTheme.corporateBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: item.formats
                          .map(
                            (format) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                format,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
