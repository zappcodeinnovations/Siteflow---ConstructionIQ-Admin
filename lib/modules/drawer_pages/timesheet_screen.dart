import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_endpoints.dart';
import 'timesheet_controller.dart';
import 'add_attendance_dialog.dart';
import '../../models/timesheet_model.dart';
import '../../core/widgets/shimmer_loading.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final TimesheetController _controller = TimesheetController();

  @override
  void initState() {
    super.initState();
    _controller.fetchTimesheets();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDate = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(
        start: initialDate.subtract(const Duration(days: 30)),
        end: initialDate,
      ),
    );
    if (picked != null) {
      final startStr = "${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
      final endStr = "${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
      _controller.setDateRange(startStr, endStr);
    }
  }

  Future<void> _downloadReport() async {
    final baseUrl = '${ApiEndpoints.baseUrl}/timesheets/export/?';
    
    List<String> queryParams = [];
    if (_controller.fromDate != null && _controller.fromDate!.isNotEmpty) queryParams.add('from=${_controller.fromDate}');
    if (_controller.toDate != null && _controller.toDate!.isNotEmpty) queryParams.add('to=${_controller.toDate}');
    if (_controller.selectedOperator != null && _controller.selectedOperator!.isNotEmpty) queryParams.add('operator=${_controller.selectedOperator}');
    if (_controller.selectedProject != null && _controller.selectedProject!.isNotEmpty) queryParams.add('project=${_controller.selectedProject}');
    if (_controller.selectedAttendanceStatus != null && _controller.selectedAttendanceStatus!.isNotEmpty) queryParams.add('attendance_status=${_controller.selectedAttendanceStatus}');
    if (_controller.selectedShiftRule != null && _controller.selectedShiftRule!.isNotEmpty) queryParams.add('shift_rule=${_controller.selectedShiftRule}');
    
    final finalUrl = queryParams.isEmpty ? baseUrl.replaceAll('/?', '/') : '$baseUrl${queryParams.join('&')}';
    final url = Uri.parse(finalUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not download report")),
        );
      }
    }
  }

  void _showAdvancedFilterDialog() {
    if (_controller.data == null) return;
    
    final options = _controller.data!.filterOptions;
    final operators = (options['operators'] as List?)?.map((e) => e['id'].toString() + "|" + e['name'].toString()).toList() ?? [];
    final projects = (options['projects'] as List?)?.map((e) => e['id'].toString() + "|" + e['name'].toString()).toList() ?? [];
    final attendanceChoices = (options['attendance_status_choices'] as List?)?.map((e) => e['value'].toString() + "|" + e['label'].toString()).toList() ?? [];
    final shiftChoices = (options['shift_rule_choices'] as List?)?.map((e) => e['value'].toString() + "|" + e['label'].toString()).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        String? tempOp = _controller.selectedOperator;
        String? tempProj = _controller.selectedProject;
        String? tempAtt = _controller.selectedAttendanceStatus;
        String? tempShift = _controller.selectedShiftRule;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Advanced Filters"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Operator"),
                      value: tempOp,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All Operators")),
                        ...operators.map((o) {
                          final parts = o.split('|');
                          return DropdownMenuItem(value: parts[0], child: Text(parts[1], overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (val) => setState(() => tempOp = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Project"),
                      value: tempProj,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All Projects")),
                        ...projects.map((p) {
                          final parts = p.split('|');
                          return DropdownMenuItem(value: parts[0], child: Text(parts[1], overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (val) => setState(() => tempProj = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Attendance Status"),
                      value: tempAtt,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All")),
                        ...attendanceChoices.map((a) {
                          final parts = a.split('|');
                          return DropdownMenuItem(value: parts[0], child: Text(parts[1], overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (val) => setState(() => tempAtt = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Shift Rule"),
                      value: tempShift,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All")),
                        ...shiftChoices.map((s) {
                          final parts = s.split('|');
                          return DropdownMenuItem(value: parts[0], child: Text(parts[1], overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (val) => setState(() => tempShift = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.setAdvancedFilters(op: tempOp, project: tempProj, status: tempAtt, shift: tempShift);
                    Navigator.pop(context);
                  },
                  child: const Text("Set Filters"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Timesheets", style: TextStyle(color: Color(0xFF0F2C4A), fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showAdvancedFilterDialog),
          IconButton(icon: const Icon(Icons.download), onPressed: _downloadReport),
         
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Date Selector and Refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text("${_controller.fromDate ?? 'Select'} - ${_controller.toDate ?? 'Date'}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        onPressed: () {
                          _controller.resetFilters();
                          _controller.fetchTimesheets();
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // KPI Grid
                  if (_controller.data?.kpi != null)
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKpiCard("Operators", _controller.data!.kpi!.operators.toString(), const Color(0xFF0D6EFD), Icons.people_outline),
                        _buildKpiCard("Records", _controller.data!.kpi!.records.toString(), Colors.grey.shade700, Icons.description_outlined),
                        _buildKpiCard("Hrs Worked", _controller.data!.kpi!.completedHours, Colors.black87, Icons.access_time),
                        _buildKpiCard("Clocked In", _controller.data!.kpi!.clockedIn.toString(), Colors.green, Icons.login),
                        _buildKpiCard("Absent", _controller.data!.kpi!.notClockedIn.toString(), Colors.red, Icons.person_off_outlined),
                        _buildKpiCard("Pending", _controller.data!.kpi!.notClockedOut.toString(), Colors.orange, Icons.pending_outlined),
                      ],
                    ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      TextButton(onPressed: () {}, child: const Text("View All", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_controller.isLoading && _controller.data == null)
                    const ShimmerLoadingList()
                  else if (_controller.errorMessage != null && _controller.data == null)
                    Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)))
                  else if (_controller.data != null)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _controller.data!.data.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _TimesheetCard(record: _controller.data!.data[index], index: index);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D6EFD),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddAttendanceDialog(controller: _controller),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TimesheetCard extends StatefulWidget {
  final TimesheetRecord record;
  final int index;
  const _TimesheetCard({required this.record, required this.index});

  @override
  State<_TimesheetCard> createState() => _TimesheetCardState();
}

class _TimesheetCardState extends State<_TimesheetCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    String statusLabel = "Completed";
    Color statusColor = Colors.grey;
    if (widget.record.attendanceState == 'clocked_in') {
      statusLabel = "Clocked In";
      statusColor = Colors.green;
    } else if (widget.record.attendanceState == 'clocked_out') {
      statusLabel = "Clocked Out";
      statusColor = Colors.grey.shade600;
    } else if (widget.record.attendanceState == 'not_clocked_in') {
      statusLabel = "Absent";
      statusColor = Colors.red;
    }

    String initials = "";
    if (widget.record.operatorName.isNotEmpty) {
      final parts = widget.record.operatorName.split(" ");
      initials = parts.length > 1 
          ? "${parts[0][0]}${parts[1][0]}" 
          : widget.record.operatorName.substring(0, 1);
    }
    initials = initials.toUpperCase();
    
    final avatarColors = [const Color(0xFF0D6EFD), const Color(0xFF0F172A), const Color(0xFFD4AF37)];
    final aColor = avatarColors[widget.index % avatarColors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: aColor,
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.record.operatorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text("OP-${widget.record.operatorCode}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(widget.record.date.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${widget.record.shiftHours} hrs", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                        Text("Total Duration", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.record.projectName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Project Code: ${widget.record.projectCode}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text("${widget.record.clockIn} - ${widget.record.clockOut}", style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    const Text("In", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    const Text("Out", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          if (widget.record.projectEntries.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade100, thickness: 2),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("PROJECT BREAKDOWN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  children: widget.record.projectEntries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${entry.clockInTime} - ${entry.clockOutTime}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(entry.projectName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          Text("${entry.shiftHours}h", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
          ]
        ],
      ),
    );
  }
}