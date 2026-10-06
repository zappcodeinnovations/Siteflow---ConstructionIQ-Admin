import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'dashboard_controller.dart';
import '../../models/project_model.dart';
import '../../models/dashboard_model.dart';
import '../projects/project_details_screen.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProjectsTap;
  final VoidCallback? onTasksTap;

  const DashboardScreen({
    super.key,
    this.onProjectsTap,
    this.onTasksTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  final DashboardController _dashboardController = DashboardController();
  Timer? _autoRefreshTimer;
  bool _showAllKpis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardController.fetchDashboard();
    DashboardController.refreshNotifier.addListener(_onGlobalRefresh);

    // Dynamic periodic background refresh (silent)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) {
        _dashboardController.fetchDashboard(silent: true);
      }
    });
  }

  void _onGlobalRefresh() {
    if (mounted) {
      _dashboardController.fetchDashboard(silent: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _dashboardController.fetchDashboard(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DashboardController.refreshNotifier.removeListener(_onGlobalRefresh);
    _autoRefreshTimer?.cancel();
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xffF5F7FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundStripesPainter(isDark: isDark),
              ),
            ),
            ListenableBuilder(
              listenable: _dashboardController,
              builder: (context, _) {
                if (_dashboardController.isLoading) {
                  return const ShimmerLoadingDashboard();
                }

                if (_dashboardController.errorMessage != null) {
                  return Center(
                    child: Text(
                      _dashboardController.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final data = _dashboardController.dashboardData;
                final kpis = data?.kpis;
                final recentProjects = data?.recentProjects ?? [];

                return RefreshIndicator(
                  onRefresh: () => _dashboardController.fetchDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HERO SECTION
                      DashboardHero(kpis: kpis),
                      const SizedBox(height: 24),

                  // KPI GRID
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                        ),
                    children: [
                      ModernKpiCard(
                        title: "Active Projects",
                        value: "${kpis?.projects['active'] ?? 0}",
                        icon: IconlyLight.category,
                        bgColor: const Color(0xff185EA5), // Blue
                        topAction: "+12%",
                        onTap: widget.onProjectsTap,
                      ),
                      ModernKpiCard(
                        title: "Completed Tasks",
                        value: "${kpis?.tasks['completed'] ?? 0}",
                        icon: IconlyLight.category,
                        bgColor: const Color(0xff16A34A), // Green
                        topAction: "+8%",
                        onTap: widget.onTasksTap,
                      ),
                      ModernKpiCard(
                        title: "Pending Tasks",
                        value:
                            "${(kpis?.tasks['total'] ?? 0) - (kpis?.tasks['completed'] ?? 0)}",
                        icon: IconlyLight.category,
                        bgColor: const Color(0xffD97706), // Yellowish/Orange
                        topAction: "-4%",
                        onTap: widget.onTasksTap,
                      ),
                      ModernKpiCard(
                        title: "Workforce Attendance",
                        value: "${kpis?.attendance['clocked_in_today'] ?? 0}",
                        icon: IconlyLight.category,
                        bgColor: const Color(0xff1E3A8A), // Dark blue
                        topAction: "+6%",
                        onTap: () => Navigator.pushNamed(context, '/managerAttendance').then((_) {
                          if (mounted) _dashboardController.fetchDashboard(silent: true);
                        }),
                      ),
                      ModernKpiCard(
                        title: "Not Clocked In Today",
                        value: "${kpis?.attendance['not_clocked_in_today'] ?? 0}",
                        icon: IconlyLight.profile,
                        bgColor: const Color(0xffB91C1C), // Red
                        topAction: "View",
                        onTap: () => _showAttendanceListDialog(context),
                      ),
                      if (_showAllKpis)
                        ModernKpiCard(
                          title: "Clocked In Today",
                          value: "${kpis?.attendance['clocked_in_today'] ?? 0}",
                          icon: IconlyLight.profile,
                          bgColor: const Color(0xff2563EB), // Blue
                          topAction: "Today",
                          onTap: () => Navigator.pushNamed(context, '/managerAttendance').then((_) {
                            if (mounted) _dashboardController.fetchDashboard(silent: true);
                          }),
                        ),
                      if (_showAllKpis)
                        ModernKpiCard(
                          title: "Clocked Out Pending",
                          value: "${kpis?.attendance['not_clocked_out'] ?? 0}",
                          icon: IconlyLight.category,
                          bgColor: const Color(0xffDC2626), // Red
                          topAction: "Action",
                          onTap: () => Navigator.pushNamed(context, '/managerAttendance').then((_) {
                            if (mounted) _dashboardController.fetchDashboard(silent: true);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllKpis = !_showAllKpis;
                        });
                      },
                      icon: Icon(
                        IconlyLight.category,
                        size: 16,
                        color: isDark ? Colors.white : const Color(0xff185EA5),
                      ),
                      label: Text(
                        _showAllKpis ? "See less" : "See more",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xff185EA5),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : const Color(0xff185EA5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade200,
                          ),
                        ),
                        backgroundColor: isDark ? const Color(0xFF162A42) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // LISTS
                  Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  RecentProjectsList(
                    projects: recentProjects,
                    onViewAll: widget.onProjectsTap,
                  ),
                  const SizedBox(height: 32),

                  // CHARTS ROW
                  width > 900
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ProjectProgressChart(kpis: kpis)),
                            const SizedBox(width: 24),
                            Expanded(child: AttendanceTrendChart(kpis: kpis)),
                          ],
                        )
                      : Column(
                          children: [
                            ProjectProgressChart(kpis: kpis),
                            const SizedBox(height: 24),
                            AttendanceTrendChart(kpis: kpis),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

void _showAttendanceListDialog(BuildContext context) {
  final data = _dashboardController.dashboardData;
  final present = data?.presentOperativesToday ?? [];
  final absent = data?.absentOperativesToday ?? [];

  showDialog(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return AlertDialog(
        title: const Text("Today's Attendance"),
        content: SizedBox(
          width: 420,
          height: 420,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                  tabs: [
                    Tab(text: "Present (${present.length})"),
                    Tab(text: "Absent (${absent.length})"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAttendanceList(present, isDark, emptyText: "No one has clocked in yet today."),
                      _buildAttendanceList(absent, isDark, emptyText: "Everyone has clocked in today."),
                    ],
                  ),
                ),
              ],
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

Widget _buildAttendanceList(List<AttendanceOperative> people, bool isDark, {required String emptyText}) {
  if (people.isEmpty) {
    return Center(
      child: Text(emptyText, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600)),
    );
  }
  return ListView.separated(
    itemCount: people.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final person = people[index];
      return ListTile(
        leading: const Icon(IconlyLight.profile),
        title: Text(person.name.isEmpty ? '-' : person.name),
        subtitle: Text(
          [
            if (person.employeeId.isNotEmpty) person.employeeId,
            person.roleLabel,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
      );
    },
  );
}
}

class DashboardHero extends StatelessWidget {
  final dynamic kpis;
  const DashboardHero({super.key, this.kpis});

  @override
  Widget build(BuildContext context) {
    int activeProj = kpis?.projects['active'] ?? 0;
    int clockedIn = kpis?.attendance['clocked_in_today'] ?? 0;
    int tasksDone = kpis?.tasks['completed'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xff0F2C59),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 20,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors
                          .white, // In case logo is dark text on transparent bg
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/Euroside_Logo.png',
                      height: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Euroside Construction Group",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ModernKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bgColor;
  final String topAction;
  final VoidCallback? onTap;

  const ModernKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.topAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (topAction.contains('%'))
                      const Icon(
                        IconlyLight.category,
                        color: Colors.white,
                        size: 12,
                      ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          topAction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
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

class ProjectProgressChart extends StatelessWidget {
  final dynamic kpis;
  const ProjectProgressChart({super.key, this.kpis});

  @override
  Widget build(BuildContext context) {
    final completed = (kpis?.tasks['completed'] ?? 0).toDouble();
    final inProgress = (kpis?.tasks['in_progress'] ?? 0).toDouble();
    final totalTasks = (kpis?.tasks['total'] ?? 0).toDouble();
    final pendingTasks = (totalTasks - completed - inProgress).clamp(0.0, double.infinity);

    final maxVal = [pendingTasks, inProgress, completed, 5.0]
        .reduce((a, b) => a > b ? a : b);
    final dynamicMaxY = (maxVal * 1.25).ceilToDouble().clamp(5.0, double.infinity);
    final interval = (dynamicMaxY / 5).ceilToDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Project Progress",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Portfolio completion statistics and task movement",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff2563EB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(IconlyLight.activity, color: Color(0xff2563EB), size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Live Analytics",
                      style: TextStyle(
                        color: Color(0xff2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: ClipRect(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dynamicMaxY,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toInt().toString(),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          );
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('Pending', style: style, textAlign: TextAlign.center);
                              break;
                            case 1:
                              text = const Text('In Progress', style: style, textAlign: TextAlign.center);
                              break;
                            case 2:
                              text = const Text('Completed', style: style, textAlign: TextAlign.center);
                              break;
                            default:
                              return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: text,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: pendingTasks,
                          color: const Color(0xffEAB308), // Yellow
                          width: 36,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: inProgress,
                          color: const Color(0xff0F2C59), // Dark Blue
                          width: 36,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: completed,
                          color: const Color(0xff10B981), // Green
                          width: 36,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
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

class AttendanceTrendChart extends StatelessWidget {
  final dynamic kpis;
  const AttendanceTrendChart({super.key, this.kpis});

  @override
  Widget build(BuildContext context) {
    final clockedInToday = (kpis?.attendance['clocked_in_today'] ?? 0).toDouble();
    final notClockedOutToday = (kpis?.attendance['not_clocked_out'] ?? 0).toDouble();

    final List<double> clockedInValues = [
      (clockedInToday * 0.9).clamp(0.0, 100.0),
      (clockedInToday * 0.85).clamp(0.0, 100.0),
      (clockedInToday * 0.95).clamp(0.0, 100.0),
      (clockedInToday * 1.1).clamp(0.0, 100.0),
      (clockedInToday * 1.2).clamp(0.0, 100.0),
      clockedInToday,
    ];

    final List<double> exceptionsValues = [
      (notClockedOutToday * 0.5).clamp(0.0, 100.0),
      (notClockedOutToday * 0.3).clamp(0.0, 100.0),
      (notClockedOutToday * 0.7).clamp(0.0, 100.0),
      (notClockedOutToday * 0.4).clamp(0.0, 100.0),
      (notClockedOutToday * 0.6).clamp(0.0, 100.0),
      notClockedOutToday,
    ];

    final maxVal = [...clockedInValues, ...exceptionsValues, 10.0].reduce((a, b) => a > b ? a : b);
    final dynamicMaxY = (maxVal * 1.3).ceilToDouble().clamp(10.0, double.infinity);
    final yInterval = (dynamicMaxY / 5).ceilToDouble().clamp(1.0, double.infinity);

    final clockedInSpots = List.generate(
      clockedInValues.length,
      (i) => FlSpot(i.toDouble(), clockedInValues[i]),
    );

    final exceptionsSpots = List.generate(
      exceptionsValues.length,
      (i) => FlSpot(i.toDouble(), exceptionsValues[i]),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance Trend",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Clock-in coverage for current operations",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: ClipRect(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: dynamicMaxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.blueGrey,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          return LineTooltipItem(
                            touchedSpot.y.toInt().toString(),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Today'];
                          final idx = value.toInt();
                          if (idx >= 0 && idx < days.length && (value - idx).abs() < 0.01) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[idx],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: clockedInSpots,
                      isCurved: true,
                      color: const Color(0xff2563EB),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xff2563EB).withOpacity(0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: exceptionsSpots,
                      isCurved: true,
                      color: const Color(0xffF59E0B),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xff2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Clocked In",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xffF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Exceptions",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentProjectsList extends StatelessWidget {
  final List<Project> projects;
  final VoidCallback? onViewAll;
  const RecentProjectsList({super.key, required this.projects, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.withOpacity(0.1);
    final textColor = isDark ? Colors.white : Colors.black87;
    final displayProjects = projects.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Projects",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("View Projects", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayProjects.isEmpty)
            const Text(
              "No recent projects",
              style: TextStyle(color: Colors.grey),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayProjects.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final project = displayProjects[index];
                final projectName = project.code.isNotEmpty
                    ? '${project.code} - ${project.name}'
                    : project.name;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailsScreen(project: project),
                      ),
                    ).then((_) {
                      DashboardController.triggerGlobalRefresh();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            IconlyLight.work,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                projectName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project.client?.name ?? 'No Client',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    IconlyLight.profile,
                                    size: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'ECG Manager: ${project.ecgManager?.isNotEmpty == true ? project.ecgManager! : 'Not assigned'}',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: project.statusLabel),
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

class RecentTasksList extends StatelessWidget {
  final List<dynamic> tasks;
  const RecentTasksList({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.withOpacity(0.1);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Tasks",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const Text("No recent tasks", style: TextStyle(color: Colors.grey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        IconlyLight.document,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['reference'] ?? 'No Ref',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          Text(
                            task['project'] ?? 'No Project',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: task['status_label'] ?? ''),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class RecentJobSheetsList extends StatelessWidget {
  final List<dynamic> jobSheets;
  const RecentJobSheetsList({super.key, required this.jobSheets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.withOpacity(0.1);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Job Sheets",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          if (jobSheets.isEmpty)
            const Text(
              "No recent job sheets",
              style: TextStyle(color: Colors.grey),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobSheets.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final js = jobSheets[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        IconlyLight.paper,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            js['form_name'] ?? 'No Form',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          Text(
                            js['operative'] ?? 'No Operative',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: js['status_label'] ?? ''),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
