import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'dashboard_controller.dart';
import '../../models/project_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _dashboardController = DashboardController();
  bool _showAllKpis = false;

  @override
  void initState() {
    super.initState();
    _dashboardController.fetchDashboard();
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: ListenableBuilder(
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
            final recentTasks = data?.recentTasks ?? [];
            final recentJobSheets = data?.recentJobSheets ?? [];

            return SingleChildScrollView(
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
                          childAspectRatio: 1.6,
                        ),
                    children: [
                      ModernKpiCard(
                        title: "Active Projects",
                        value: "${kpis?.projects['active'] ?? 0}",
                        icon: Icons.pause_circle_outline,
                        bgColor: const Color(0xff185EA5), // Blue
                        topAction: "+12%",
                      ),
                      ModernKpiCard(
                        title: "Completed Projects",
                        value: "${kpis?.projects['completed'] ?? 0}",
                        icon: Icons.check_circle_outline,
                        bgColor: const Color(0xff16A34A), // Green
                        topAction: "+8%",
                      ),
                      ModernKpiCard(
                        title: "Pending Tasks",
                        value:
                            "${(kpis?.tasks['total'] ?? 0) - (kpis?.tasks['completed'] ?? 0)}",
                        icon: Icons.list_alt,
                        bgColor: const Color(0xffD97706), // Yellowish/Orange
                        topAction: "-4%",
                      ),
                      ModernKpiCard(
                        title: "Workforce Attendance",
                        value: "${kpis?.attendance['clocked_in_today'] ?? 0}",
                        icon: Icons.people_outline,
                        bgColor: const Color(0xff1E3A8A), // Dark blue
                        topAction: "+6%",
                      ),
                      if (_showAllKpis)
                        ModernKpiCard(
                          title: "Clocked In Today",
                          value: "${kpis?.attendance['clocked_in_today'] ?? 0}",
                          icon: Icons.person_outline,
                          bgColor: const Color(0xff2563EB), // Blue
                          topAction: "Today",
                        ),
                      if (_showAllKpis)
                        ModernKpiCard(
                          title: "Clocked Out Pending",
                          value: "${kpis?.attendance['not_clocked_out'] ?? 0}",
                          icon: Icons.exit_to_app,
                          bgColor: const Color(0xffDC2626), // Red
                          topAction: "Action",
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
                        _showAllKpis ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(_showAllKpis ? "See less" : "See more"),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff185EA5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CHARTS ROW
                  width > 900
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ProjectProgressChart(kpis: kpis)),
                            const SizedBox(width: 24),
                            Expanded(child: AttendanceTrendChart()),
                          ],
                        )
                      : Column(
                          children: [
                            ProjectProgressChart(kpis: kpis),
                            const SizedBox(height: 24),
                            AttendanceTrendChart(),
                          ],
                        ),
                  const SizedBox(height: 32),

                  // LISTS
                  Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (width > 1200)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RecentProjectsList(projects: recentProjects),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: RecentTasksList(tasks: recentTasks)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: RecentJobSheetsList(
                            jobSheets: recentJobSheets,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        RecentProjectsList(projects: recentProjects),
                        const SizedBox(height: 20),
                        RecentTasksList(tasks: recentTasks),
                        const SizedBox(height: 20),
                        RecentJobSheetsList(jobSheets: recentJobSheets),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
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
                      color: Colors.white, // In case logo is dark text on transparent bg
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

  const ModernKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.topAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        Icons.arrow_outward,
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
    );
  }
}

class ProjectProgressChart extends StatelessWidget {
  final dynamic kpis;
  const ProjectProgressChart({super.key, this.kpis});

  @override
  Widget build(BuildContext context) {
    final active = (kpis?.projects['active'] ?? 0).toDouble();
    final completed = (kpis?.projects['completed'] ?? 0).toDouble();
    final pendingTasks =
        (kpis?.tasks['total'] ?? 0).toDouble() -
        (kpis?.tasks['completed'] ?? 0).toDouble();
    final tasksDone = (kpis?.tasks['completed'] ?? 0).toDouble();

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
            children: [
              Column(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.analytics, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Live Analytics",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
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
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5, // Just for illustration
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Active', style: style);
                            break;
                          case 1:
                            text = const Text('Completed', style: style);
                            break;
                          case 2:
                            text = const Text('Pending Tasks', style: style);
                            break;
                          case 3:
                            text = const Text('In Progress', style: style);
                            break;
                          case 4:
                            text = const Text('Done', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
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
                  horizontalInterval: 1,
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
                        toY: active > 0 ? active : 2,
                        color: const Color(0xff185EA5),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: completed > 0 ? completed : 0,
                        color: const Color(0xff16A34A),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: pendingTasks > 0 ? pendingTasks : 1,
                        color: const Color(0xffD97706),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 0,
                        color: const Color(0xff6366F1),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: tasksDone > 0 ? tasksDone : 1,
                        color: const Color(0xff22C55E),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceTrendChart extends StatelessWidget {
  const AttendanceTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
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
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Mon', style: style);
                            break;
                          case 1:
                            text = const Text('Tue', style: style);
                            break;
                          case 2:
                            text = const Text('Wed', style: style);
                            break;
                          case 3:
                            text = const Text('Thu', style: style);
                            break;
                          case 4:
                            text = const Text('Fri', style: style);
                            break;
                          case 5:
                            text = const Text('Today', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
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
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 30,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 28),
                      FlSpot(2, 0),
                      FlSpot(3, 29),
                      FlSpot(4, 0),
                      FlSpot(5, 28),
                    ],
                    isCurved: true,
                    color: const Color(0xffF59E0B),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 0),
                      FlSpot(2, 0),
                      FlSpot(3, 0),
                      FlSpot(4, 0),
                      FlSpot(5, 0),
                    ],
                    isCurved: true,
                    color: const Color(0xff2563EB),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
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
  const RecentProjectsList({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Projects",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            const Text(
              "No recent projects",
              style: TextStyle(color: Colors.grey),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final project = projects[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.domain,
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
                            project.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            project.client?.name ?? 'No Client',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: project.statusLabel),
                  ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Tasks",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        Icons.assignment,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Job Sheets",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        Icons.description,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
