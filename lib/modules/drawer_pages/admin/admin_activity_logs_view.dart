import 'package:flutter/material.dart';
import 'admin_activity_logs_controller.dart';
import 'activity_log_details_dialog.dart';
import '../../../core/widgets/shimmer_loading.dart';

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
  String? _selectedModule;
  String? _selectedAction;

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
      _selectedModule = null;
      _selectedAction = null;
      _searchController.clear();
      _fromDateController.clear();
      _toDateController.clear();
    });
    _controller.resetFilters();
  }

  Future<void> _selectDate(TextEditingController textController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        textController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildKpiCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPill(String action) {
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade700;

    if (action.toLowerCase().contains('login') || action.toLowerCase().contains('logout')) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (action.toLowerCase().contains('delete') || action.toLowerCase().contains('remove')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else if (action.toLowerCase().contains('update') || action.toLowerCase().contains('edit')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(action, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header & Export
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Activity Logs", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                const SizedBox(height: 4),
                Text("See who changed what, when, and from where.", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _controller.exportLogs('csv'),
                  icon: const Icon(Icons.file_download_outlined, size: 16, color: Colors.black87),
                  label: const Text("CSV", style: TextStyle(color: Colors.black87)),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _controller.exportLogs('excel'),
                  icon: const Icon(Icons.table_chart_outlined, size: 16, color: Colors.black87),
                  label: const Text("Excel", style: TextStyle(color: Colors.black87)),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _controller.exportLogs('pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.black87),
                  label: const Text("PDF", style: TextStyle(color: Colors.black87)),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),

        // KPIs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final kpi = _controller.kpi;
            return Row(
              children: [
                _buildKpiCard("TOTAL LOGS", kpi?.totalLogs.toString() ?? "0"),
                const SizedBox(width: 16),
                _buildKpiCard("TODAY LOGINS", kpi?.todayLogins.toString() ?? "0"),
                const SizedBox(width: 16),
                _buildKpiCard("TODAY CREATES", kpi?.todayCreates.toString() ?? "0"),
                const SizedBox(width: 16),
                _buildKpiCard("TODAY ERRORS", kpi?.todayErrors.toString() ?? "0"),
                const SizedBox(width: 16),
                _buildKpiCard("UNIQUE USERS TODAY", kpi?.uniqueUsersToday.toString() ?? "0"),
              ],
            );
          }
        ),
        const SizedBox(height: 24),

        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()),
                      hint: const Text("All managers"),
                      value: _selectedManager,
                      items: (_controller.filterOptions['users'] as List?)?.map((u) => DropdownMenuItem<String>(value: u['id'].toString(), child: Text(u['display_name'] ?? u['email'] ?? 'Unknown'))).toList() ?? [],
                      onChanged: (val) => setState(() => _selectedManager = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(hintText: "Manager", contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(), suffixIcon: Icon(Icons.keyboard_arrow_down)),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()),
                      hint: const Text("All modules"),
                      value: _selectedModule,
                      items: (_controller.filterOptions['modules'] as List?)?.map((m) => DropdownMenuItem<String>(value: m.toString(), child: Text(m.toString()))).toList() ?? [],
                      onChanged: (val) => setState(() => _selectedModule = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()),
                      hint: const Text("All actions"),
                      value: _selectedAction,
                      items: (_controller.filterOptions['actions'] as List?)?.map((a) => DropdownMenuItem<String>(value: a['type'].toString(), child: Text(a['label'].toString()))).toList() ?? [],
                      onChanged: (val) => setState(() => _selectedAction = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(_fromDateController),
                      child: TextField(
                        controller: _fromDateController,
                        enabled: false,
                        decoration: const InputDecoration(hintText: "YYYY-MM-DD", contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(_toDateController),
                      child: TextField(
                        controller: _toDateController,
                        enabled: false,
                        decoration: const InputDecoration(hintText: "YYYY-MM-DD", contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(hintText: "Search keyword", contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.search, size: 16, color: Colors.white),
                    label: const Text("Search", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text("Reset", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const ShimmerLoadingList();
                }

                if (_controller.errorMessage != null && _controller.logs.isEmpty) {
                  return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      color: const Color(0xFF0F2C4A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const Row(
                        children: [
                          Expanded(flex: 1, child: Text("MANAGER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(flex: 2, child: Text("MODULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(flex: 2, child: Text("ACTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(flex: 2, child: Text("BEFORE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(flex: 2, child: Text("AFTER / ACTIVITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(flex: 1, child: Text("WHEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          SizedBox(width: 100), // Action col space
                        ],
                      ),
                    ),
                    // Body
                    Expanded(
                      child: ListView.separated(
                        itemCount: _controller.logs.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final log = _controller.logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 1, child: Text(log.managerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.module, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    if (log.moduleDetail.isNotEmpty) Text(log.moduleDetail, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                  ],
                                )),
                                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _buildActionPill(log.action))),
                                Expanded(flex: 2, child: Text(log.beforeState, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 2, child: Text(log.afterState, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 1, child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.whenDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text(log.whenTime, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                  ],
                                )),
                                SizedBox(
                                  width: 100,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => ActivityLogDetailsDialog(controller: _controller, logId: log.id),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text("View Details", style: TextStyle(color: Colors.black87, fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ],
    );
  }
}
