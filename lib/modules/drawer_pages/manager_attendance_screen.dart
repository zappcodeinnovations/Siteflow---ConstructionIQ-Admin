import 'package:flutter/material.dart';
import 'manager_attendance_controller.dart';
import '../../models/manager_attendance_model.dart';
import '../../core/widgets/shimmer_loading.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() => _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  final ManagerAttendanceController _controller = ManagerAttendanceController();
  bool _isClocking = false;

  @override
  void initState() {
    super.initState();
    _controller.fetchFilterOptions();
    _controller.fetchManagerAttendance();
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

  Future<void> _handleClockAction() async {
    final kpi = _controller.data?.kpi;
    if (kpi == null) return;

    final isClockedIn = kpi.currentStatus == 'Clocked In';
    final action = isClockedIn ? 'clock_out' : 'clock_in';

    setState(() {
      _isClocking = true;
    });

    final result = await _controller.clockAction(action);

    if (!mounted) return;
    setState(() {
      _isClocking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  void _showLogsDialog(ManagerAttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 800,
            height: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Attendance Logs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Summary chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Chip(label: Text("First Login: ${record.summaryFirstLogin}"), backgroundColor: Colors.grey.shade100),
                    Chip(label: Text("Last Logout: ${record.summaryLastLogout}"), backgroundColor: Colors.grey.shade100),
                    Chip(label: Text("Total Worked: ${record.summaryTotalWorked}"), backgroundColor: Colors.grey.shade100),
                    Chip(label: Text("Clock Logs: ${record.summaryLogCount}"), backgroundColor: Colors.grey.shade100),
                  ],
                ),
                const SizedBox(height: 16),

                // Table Header
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF0F2C4A), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildHeaderCell("DATE", 2),
                      _buildHeaderCell("CLOCK IN", 1),
                      _buildHeaderCell("CLOCK OUT", 1),
                      _buildHeaderCell("HOURS", 1),
                      _buildHeaderCell("START LOCATION", 3),
                      _buildHeaderCell("END LOCATION", 3),
                      _buildHeaderCell("NOTES", 3),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: ListView.separated(
                    itemCount: record.logEntries.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final log = record.logEntries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDataCell(log.date, 2),
                            _buildDataCell(log.clockIn, 1, isBold: true),
                            _buildDataCell(log.clockOut, 1, isBold: true),
                            _buildDataCell(log.hours, 1),
                            _buildDataCell(log.startLocation, 3, isEllipsis: false),
                            _buildDataCell(log.endLocation, 3, isEllipsis: false),
                            _buildDataCell(log.notes, 3, isEllipsis: false),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeaderCell(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDataCell(String value, int flex, {bool isBold = false, bool isEllipsis = true, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.black87,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
        overflow: isEllipsis ? TextOverflow.ellipsis : null,
      ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
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
        title: const Text("Manager Attendance", style: TextStyle(color: Color(0xFF0F2C4A), fontSize: 22, fontWeight: FontWeight.bold)),
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
                  // Manager Filter
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Filter by Manager", 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          value: _controller.selectedManager,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text("All Managers")),
                            ..._controller.managersList.map((m) {
                              return DropdownMenuItem(value: m['id'].toString(), child: Text(m['name'].toString(), overflow: TextOverflow.ellipsis));
                            }),
                          ],
                          onChanged: (val) {
                            _controller.setManager(val);
                            _controller.fetchManagerAttendance();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Top Row: Date Selector, Refresh, Clock Action
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                            mainAxisSize: MainAxisSize.min,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            onPressed: () {
                              _controller.resetFilters();
                              _controller.fetchManagerAttendance();
                            },
                          ),
                          const SizedBox(width: 8),
                          if (_controller.data?.kpi != null) ...[
                            Builder(
                              builder: (context) {
                                final isClockedIn = _controller.data!.kpi!.currentStatus == 'Clocked In';
                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isClockedIn ? Colors.orange : const Color(0xFF0D6EFD),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: _isClocking ? null : _handleClockAction,
                                  icon: _isClocking 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.access_time, color: Colors.white, size: 18),
                                  label: Text(isClockedIn ? "Clock Out" : "Clock In", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                );
                              }
                            ),
                          ],
                        ],
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
                      childAspectRatio: 2.0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKpiCard("Total Entries", _controller.data!.kpi!.entries.toString(), const Color(0xFF0D6EFD), Icons.list_alt),
                        _buildKpiCard("Total Hours", _controller.data!.kpi!.completedHours, Colors.black87, Icons.access_time),
                        _buildKpiCard("Current Status", _controller.data!.kpi!.currentStatus, _controller.data!.kpi!.currentStatus == 'Clocked In' ? Colors.green : Colors.grey.shade600, Icons.info_outline),
                        _buildKpiCard("Active Since", _controller.data!.kpi!.clockedInSince ?? "N/A", Colors.purple, Icons.history),
                      ],
                    ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Active Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                        return _ManagerAttendanceCard(record: _controller.data!.data[index], index: index);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManagerAttendanceCard extends StatefulWidget {
  final ManagerAttendanceRecord record;
  final int index;
  const _ManagerAttendanceCard({required this.record, required this.index});

  @override
  State<_ManagerAttendanceCard> createState() => _ManagerAttendanceCardState();
}

class _ManagerAttendanceCardState extends State<_ManagerAttendanceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    String statusLabel = widget.record.isOpenSession ? "Open Session" : "Closed";
    Color statusColor = widget.record.isOpenSession ? Colors.orange : Colors.grey.shade600;
    if (widget.record.isOpenSession && widget.record.clockOut.isEmpty) {
      statusLabel = "Clocked In";
      statusColor = Colors.green;
    }

    String initials = "";
    if (widget.record.managerName.isNotEmpty) {
      final parts = widget.record.managerName.split(" ");
      initials = parts.length > 1 
          ? "${parts[0][0]}${parts[1][0]}" 
          : widget.record.managerName.substring(0, 1);
    }
    initials = initials.toUpperCase();
    
    final avatarColors = [const Color(0xFF0D6EFD), const Color(0xFF0F172A), const Color(0xFF0D9488)];
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
                      Row(
                        children: [
                          Flexible(child: Text(widget.record.managerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          if (widget.record.role.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text(widget.record.role.toUpperCase(), style: TextStyle(color: Colors.purple.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Text(widget.record.managerCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
                        Text("${widget.record.hours} hrs", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                        Text("Total Worked", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text("${widget.record.summaryFirstLogin} - ${widget.record.summaryLastLogout}", style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.record.startLocation, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),

          if (widget.record.logEntries.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade100, thickness: 2),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("DAILY ACTIVITY LOGS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  children: widget.record.logEntries.map((log) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.circle, size: 10, color: log.isOpen ? Colors.orange : Colors.blue),
                              Container(width: 2, height: 40, color: Colors.grey.shade200),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${log.clockIn} - ${log.clockOut}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                      child: Text("${log.hours}h", style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(log.startLocation, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                if (log.notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                                    child: Text('"${log.notes}"', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                                  ),
                                ]
                              ],
                            ),
                          ),
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
