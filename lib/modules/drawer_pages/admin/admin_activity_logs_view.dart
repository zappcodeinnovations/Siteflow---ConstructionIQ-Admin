import 'package:flutter/material.dart';
import 'admin_activity_logs_controller.dart';
import 'activity_log_details_view.dart';
import '../../../core/widgets/custom_date_picker_dialog.dart';
import '../../../core/theme/app_theme.dart';
import 'package:iconly/iconly.dart';

class AdminActivityLogsView extends StatefulWidget {
  const AdminActivityLogsView({super.key});

  @override
  State<AdminActivityLogsView> createState() => _AdminActivityLogsViewState();
}

class _AdminActivityLogsViewState extends State<AdminActivityLogsView> {
  final AdminActivityLogsController _controller = AdminActivityLogsController();

  final _searchController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  String? _selectedManager;
  String? _selectedRole;
  String? _selectedModule;
  String? _selectedAction;

  bool _isFilterExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller.initializeData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    _controller.updateFilters(
      manager: _selectedManager,
      role: _selectedRole,
      module: _selectedModule,
      action: _selectedAction,
      from: _fromDateController.text,
      to: _toDateController.text,
      search: _searchController.text,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedManager = null;
      _selectedRole = null;
      _selectedModule = null;
      _selectedAction = null;
      _searchController.clear();
      _fromDateController.clear();
      _toDateController.clear();
    });
    _controller.resetFilters();
  }

  Future<void> _selectDate(TextEditingController textController) async {
    final DateTime? picked = await CustomDatePickerDialog.showCustomDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        textController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Widget _buildKpiCard(
    String title,
    String value, {
    double? width,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill(String action) {
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade700;

    if (action.toLowerCase().contains('login') ||
        action.toLowerCase().contains('logout')) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (action.toLowerCase().contains('delete') ||
        action.toLowerCase().contains('remove')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else if (action.toLowerCase().contains('update') ||
        action.toLowerCase().contains('edit')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final fieldFillColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Export
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Activity Logs",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "See who changed what, when, and from where.",
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildExportButton("CSV", 'csv', borderColor, cardColor),
                              const SizedBox(width: 8),
                              _buildExportButton("Excel", 'excel', borderColor, cardColor),
                              const SizedBox(width: 8),
                              _buildExportButton("PDF", 'pdf', borderColor, cardColor),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Activity Logs",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "See who changed what, when, and from where.",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildExportButton("CSV", 'csv', borderColor, cardColor),
                            const SizedBox(width: 8),
                            _buildExportButton("Excel", 'excel', borderColor, cardColor),
                            const SizedBox(width: 8),
                            _buildExportButton("PDF", 'pdf', borderColor, cardColor),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 20),

              // KPIs
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final kpi = _controller.kpi;
                  if (isMobile) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                "TOTAL MANAGERS",
                                kpi?.totalManagers.toString() ?? "0",
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildKpiCard(
                                "ACTIVE MANAGERS",
                                kpi?.activeManagers.toString() ?? "0",
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                "TODAY'S ACTIVITIES",
                                kpi?.todayActivities.toString() ?? "0",
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildKpiCard(
                                "THIS MONTH",
                                kpi?.thisMonth.toString() ?? "0",
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                "FAILED LOGINS",
                                kpi?.failedLogins.toString() ?? "0",
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          "TOTAL MANAGERS",
                          kpi?.totalManagers.toString() ?? "0",
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          "ACTIVE MANAGERS",
                          kpi?.activeManagers.toString() ?? "0",
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          "TODAY'S ACTIVITIES",
                          kpi?.todayActivities.toString() ?? "0",
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          "THIS MONTH",
                          kpi?.thisMonth.toString() ?? "0",
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          "FAILED LOGINS",
                          kpi?.failedLogins.toString() ?? "0",
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  IconlyLight.filter,
                                  size: 18,
                                  color: Color(0xFF0F2C4A),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Filter Logs",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isFilterExpanded
                                  ? IconlyLight.arrow_up_2
                                  : IconlyLight.arrow_down_2,
                              size: 18,
                              color: subtitleColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(
                        width: double.infinity,
                        height: 0,
                      ),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 14,
                            children: [
                              _buildModernDropdown(
                                width: isMobile ? double.infinity : 180,
                                hint: "All managers",
                                value: _selectedManager,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: "",
                                    child: Text("All managers"),
                                  ),
                                  ..._controller.availableManagers.map(
                                    (u) {
                                      final name = (u['display_name'] ??
                                              u['name'] ??
                                              '')
                                          .toString()
                                          .trim();
                                      final email =
                                          (u['email'] ?? '').toString().trim();
                                      final label = name.isNotEmpty
                                          ? name
                                          : (email.isNotEmpty
                                              ? email
                                              : 'Unknown');
                                      return DropdownMenuItem<String>(
                                        value: u['id'].toString(),
                                        child: Text(
                                          label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                onChanged: (val) => setState(() =>
                                    _selectedManager =
                                        (val != null && val.isNotEmpty)
                                            ? val
                                            : null),
                              ),
                              _buildModernDropdown(
                                width: isMobile ? double.infinity : 150,
                                hint: "Role",
                                value: _selectedRole,
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: "",
                                    child: Text("All roles"),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: "Manager",
                                    child: Text("Manager"),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: "Super Admin",
                                    child: Text("Super Admin"),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: "Admin",
                                    child: Text("Admin"),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: "Operative",
                                    child: Text("Operative"),
                                  ),
                                ],
                                onChanged: (val) => setState(() =>
                                    _selectedRole = (val != null && val.isNotEmpty)
                                        ? val
                                        : null),
                              ),
                              _buildModernDropdown(
                                width: isMobile ? double.infinity : 160,
                                hint: "All modules",
                                value: _selectedModule,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: "",
                                    child: Text("All modules"),
                                  ),
                                  ...((_controller.filterOptions['modules']
                                          as List?)
                                      ?.map(
                                        (m) => DropdownMenuItem<String>(
                                          value: m.toString(),
                                          child: Text(
                                            m.toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList() ??
                                  []),
                                ],
                                onChanged: (val) => setState(() =>
                                    _selectedModule = (val != null && val.isNotEmpty)
                                        ? val
                                        : null),
                              ),
                              _buildModernDropdown(
                                width: isMobile ? double.infinity : 160,
                                hint: "All actions",
                                value: _selectedAction,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: "",
                                    child: Text("All actions"),
                                  ),
                                  ...((_controller.filterOptions['actions']
                                          as List?)
                                      ?.map(
                                        (a) {
                                          final val = (a is Map
                                                  ? (a['type'] ??
                                                      a['value'] ??
                                                      a['action'])
                                                  : a)
                                              .toString();
                                          final label = (a is Map
                                                  ? (a['label'] ??
                                                      a['name'] ??
                                                      a['type'])
                                                  : a)
                                              .toString();
                                          return DropdownMenuItem<String>(
                                            value: val,
                                            child: Text(
                                              label,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      )
                                      .toList() ??
                                  []),
                                ],
                                onChanged: (val) => setState(() =>
                                    _selectedAction = (val != null && val.isNotEmpty)
                                        ? val
                                        : null),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? (constraints.maxWidth - 52) / 2
                                    : 150,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _selectDate(_fromDateController),
                                  child: TextField(
                                    controller: _fromDateController,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      hintText: "dd-mm-yyyy",
                                      filled: true,
                                      fillColor: fieldFillColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: Icon(
                                        IconlyLight.calendar,
                                        size: 18,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? (constraints.maxWidth - 52) / 2
                                    : 150,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _selectDate(_toDateController),
                                  child: TextField(
                                    controller: _toDateController,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      hintText: "dd-mm-yyyy",
                                      filled: true,
                                      fillColor: fieldFillColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: Icon(
                                        IconlyLight.calendar,
                                        size: 18,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: isMobile ? double.infinity : 280,
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: "Search keyword",
                                    hintStyle: TextStyle(color: subtitleColor),
                                    filled: true,
                                    fillColor: fieldFillColor,
                                    prefixIcon: Icon(
                                      IconlyLight.search,
                                      color: subtitleColor,
                                      size: 18,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _applyFilters,
                                icon: const Icon(
                                  IconlyLight.search,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Search",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: _resetFilters,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: borderColor),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Reset",
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      crossFadeState: _isFilterExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Table
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    if (_controller.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (_controller.errorMessage != null &&
                        _controller.logs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _controller.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _controller.fetchLogs(),
                                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                                label: const Text("Retry", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (_controller.logs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconlyLight.document,
                                size: 48,
                                color: subtitleColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No activity logs found",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _controller.logs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final log = _controller.logs[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.blue.shade50,
                                          child: Icon(
                                            IconlyLight.profile,
                                            size: 20,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log.managerName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: textColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                log.module +
                                                    (log.moduleDetail.isNotEmpty
                                                        ? ' • ${log.moduleDetail}'
                                                        : ''),
                                                style: TextStyle(
                                                  color: subtitleColor,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildActionPill(log.action),
                                ],
                              ),
                              if (log.beforeState != '-' ||
                                  log.afterState != '-') ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Before",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              log.beforeState,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          IconlyLight.arrow_right_2,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "After / Activity",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              log.afterState,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        IconlyLight.calendar,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${log.whenDate} at ${log.whenTime}",
                                        style: TextStyle(
                                          color: subtitleColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ActivityLogDetailsView(
                                                controller: _controller,
                                                logId: log.id,
                                              ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue.shade700,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Details",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportButton(
    String label,
    String format,
    Color borderColor,
    Color cardColor,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _controller.exportLogs(format),
      icon: const Icon(
        IconlyLight.download,
        size: 15,
        color: Color(0xFF0F2C4A),
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F2C4A),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor),
        backgroundColor: cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required double width,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        hint: Text(hint),
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
