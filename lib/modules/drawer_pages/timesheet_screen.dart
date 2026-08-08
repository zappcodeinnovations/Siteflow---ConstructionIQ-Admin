import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'timesheet_controller.dart';
import 'add_attendance_dialog.dart';
import 'attendance_logs_dialog.dart';
import '../../models/timesheet_model.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

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
      _controller.fetchTimesheets();
    }
  }

  Future<void> _downloadReport() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading report...")),
        );
      }

      final baseUrl = '${ApiEndpoints.baseUrl}/timesheets/export/?';
      
      List<String> queryParams = [];
      if (_controller.fromDate != null && _controller.fromDate!.isNotEmpty) queryParams.add('from=${_controller.fromDate}');
      if (_controller.toDate != null && _controller.toDate!.isNotEmpty) queryParams.add('to=${_controller.toDate}');
      if (_controller.selectedOperator != null && _controller.selectedOperator!.isNotEmpty) queryParams.add('operator=${_controller.selectedOperator}');
      if (_controller.selectedProject != null && _controller.selectedProject!.isNotEmpty) queryParams.add('project=${_controller.selectedProject}');
      if (_controller.selectedAttendanceStatus != null && _controller.selectedAttendanceStatus!.isNotEmpty) queryParams.add('attendance_status=${_controller.selectedAttendanceStatus}');
      if (_controller.selectedShiftRule != null && _controller.selectedShiftRule!.isNotEmpty) queryParams.add('shift_rule=${_controller.selectedShiftRule}');
      
      final finalUrl = queryParams.isEmpty ? baseUrl.replaceAll('/?', '/') : '$baseUrl${queryParams.join('&')}';
      
      final response = await ApiClient.get(finalUrl);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/timesheets_report.xlsx');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        await Share.shareXFiles([XFile(file.path)], text: 'Timesheets Report');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download failed. Status: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showAdvancedFilterDialog() {
    if (_controller.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait for data to load before filtering.")),
      );
      return;
    }
    
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? AppTheme.corporateBlue : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final iconBgColor = isDark ? Colors.white24 : Colors.grey.shade100;
            final iconColor = isDark ? Colors.white : Colors.black54;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Advanced Filters",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                              child: Icon(IconlyLight.close_square, size: 18, color: iconColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildPremiumDropdown(
                        context,
                        "Operator", 
                        tempOp, 
                        [
                          const DropdownMenuItem(value: null, child: Text("All Operators")),
                          ...operators.map((o) {
                            final parts = o.split('|');
                            return DropdownMenuItem(value: parts[0], child: Text(parts.length > 1 ? parts[1] : parts[0], overflow: TextOverflow.ellipsis));
                          })
                        ], 
                        (val) => setState(() => tempOp = val)
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumDropdown(
                        context,
                        "Project", 
                        tempProj, 
                        [
                          const DropdownMenuItem(value: null, child: Text("All Projects")),
                          ...projects.map((p) {
                            final parts = p.split('|');
                            return DropdownMenuItem(value: parts[0], child: Text(parts.length > 1 ? parts[1] : parts[0], overflow: TextOverflow.ellipsis));
                          })
                        ], 
                        (val) => setState(() => tempProj = val)
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumDropdown(
                        context,
                        "Attendance Status", 
                        tempAtt, 
                        [
                          const DropdownMenuItem(value: null, child: Text("All")),
                          ...attendanceChoices.map((a) {
                            final parts = a.split('|');
                            return DropdownMenuItem(value: parts[0], child: Text(parts.length > 1 ? parts[1] : parts[0], overflow: TextOverflow.ellipsis));
                          })
                        ], 
                        (val) => setState(() => tempAtt = val)
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumDropdown(
                        context,
                        "Shift Rule", 
                        tempShift, 
                        [
                          const DropdownMenuItem(value: null, child: Text("All")),
                          ...shiftChoices.map((s) {
                            final parts = s.split('|');
                            return DropdownMenuItem(value: parts[0], child: Text(parts.length > 1 ? parts[1] : parts[0], overflow: TextOverflow.ellipsis));
                          })
                        ], 
                        (val) => setState(() => tempShift = val)
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              onPressed: () {
                                setState(() {
                                  tempOp = null;
                                  tempProj = null;
                                  tempAtt = null;
                                  tempShift = null;
                                });
                              },
                              child: Text("Clear All", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                _controller.setAdvancedFilters(op: tempOp, project: tempProj, status: tempAtt, shift: tempShift);
                                _controller.fetchTimesheets();
                                Navigator.pop(context);
                              },
                              child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        );
      }
    );
  }

  Widget _buildPremiumDropdown(BuildContext context, String label, String? currentValue, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: boxBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentValue,
              dropdownColor: dropdownColor,
              style: TextStyle(color: textColor, fontSize: 14),
              icon: Icon(IconlyLight.arrow_down_2, color: iconColor),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : color.withOpacity(0.3);
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isDark ? Colors.white : color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
        title: Text("Timesheets", style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F2C4A), fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(IconlyLight.filter), onPressed: _showAdvancedFilterDialog),
          IconButton(icon: const Icon(IconlyLight.download), onPressed: _downloadReport),
        ],
      ),
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
                  // Top Row: Date Selector and Refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.corporateBlue : Colors.white,
                            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(IconlyLight.calendar, size: 14, color: isDark ? Colors.white : Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text("${_controller.fromDate ?? 'Select'} - ${_controller.toDate ?? 'Date'}", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                              const SizedBox(width: 4),
                              Icon(IconlyLight.arrow_down_2, size: 16, color: isDark ? Colors.white70 : Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(IconlyLight.swap, color: isDark ? Colors.white : Colors.blue),
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
                      childAspectRatio: 1.4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKpiCard("Operators", _controller.data!.kpi!.operators.toString(), const Color(0xFF0D6EFD), IconlyLight.category),
                        _buildKpiCard("Records", _controller.data!.kpi!.records.toString(), Colors.grey.shade700, IconlyLight.paper),
                        _buildKpiCard("Hrs Worked", _controller.data!.kpi!.completedHours, Colors.black87, IconlyLight.time_circle),
                        _buildKpiCard("Clocked In", _controller.data!.kpi!.clockedIn.toString(), Colors.green, IconlyLight.category),
                        _buildKpiCard("Absent", _controller.data!.kpi!.notClockedIn.toString(), Colors.red, IconlyLight.category),
                        _buildKpiCard("Pending", _controller.data!.kpi!.notClockedOut.toString(), Colors.orange, IconlyLight.category),
                      ],
                    ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recent Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      TextButton(onPressed: () {}, child: Text("View All", style: TextStyle(color: isDark ? Colors.white : Colors.blue, fontWeight: FontWeight.w600))),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D6EFD),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddAttendanceDialog(controller: _controller),
          );
        },
        child: const Icon(IconlyLight.plus, color: Colors.white),
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

  static final Map<String, String> _addressCache = {};
  
  String _startAddress = "";
  String _endAddress = "";
  final Map<int, String> _entryStartAddresses = {};
  final Map<int, String> _entryEndAddresses = {};

  @override
  void initState() {
    super.initState();
    _startAddress = widget.record.startLocation;
    _endAddress = widget.record.endLocation;
    
    for (int i = 0; i < widget.record.projectEntries.length; i++) {
      _entryStartAddresses[i] = widget.record.projectEntries[i].startLocation;
      _entryEndAddresses[i] = widget.record.projectEntries[i].endLocation;
    }
    
    _resolveAddresses();
  }

  Future<void> _resolveAddresses() async {
    _startAddress = await _getAddressFromCoordinates(widget.record.startLocation);
    _endAddress = await _getAddressFromCoordinates(widget.record.endLocation);
    
    for (int i = 0; i < widget.record.projectEntries.length; i++) {
      final entry = widget.record.projectEntries[i];
      _entryStartAddresses[i] = await _getAddressFromCoordinates(entry.startLocation);
      _entryEndAddresses[i] = await _getAddressFromCoordinates(entry.endLocation);
    }
    
    if (mounted) setState(() {});
  }

  Future<String> _getAddressFromCoordinates(String latLongStr) async {
    if (latLongStr.isEmpty || latLongStr == "N/A") return "N/A";
    
    if (_addressCache.containsKey(latLongStr)) {
      return _addressCache[latLongStr]!;
    }
    
    try {
      final parts = latLongStr.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            List<String> addressParts = [];
            if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
            if (p.street != null && p.street!.isNotEmpty && p.street != p.name) addressParts.add(p.street!);
            if (p.subLocality != null && p.subLocality!.isNotEmpty) addressParts.add(p.subLocality!);
            if (p.locality != null && p.locality!.isNotEmpty) addressParts.add(p.locality!);
            if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) addressParts.add(p.subAdministrativeArea!);
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) addressParts.add(p.administrativeArea!);
            if (p.country != null && p.country!.isNotEmpty) addressParts.add(p.country!);
            if (p.postalCode != null && p.postalCode!.isNotEmpty) addressParts.add(p.postalCode!);
            
            final address = addressParts.join(', ');
            _addressCache[latLongStr] = address;
            return address;
          }
        }
      }
    } catch (e) {
      debugPrint("Geocoding failed for $latLongStr: $e");
    }
    _addressCache[latLongStr] = latLongStr;
    return latLongStr;
  }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
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
                      Text(widget.record.operatorName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      Text("OP-${widget.record.operatorCode}", style: TextStyle(fontSize: 12, color: textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IconlyLight.category, size: 8, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
          
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
                        Icon(IconlyLight.calendar, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(widget.record.date.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.5)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${widget.record.shiftHours} hrs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0D6EFD))),
                        Text("Total Duration", style: TextStyle(fontSize: 10, color: textSecondary)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.record.projectName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                Text("Project Code: ${widget.record.projectCode}", style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(IconlyLight.time_circle, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Text("${widget.record.clockIn} - ${widget.record.clockOut}", style: TextStyle(fontSize: 13, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(IconlyLight.location, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("In", style: TextStyle(fontSize: 10, color: textSecondary)),
                                Text(_startAddress.isNotEmpty ? _startAddress : "N/A", style: TextStyle(fontSize: 11, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(IconlyLight.location, size: 14, color: Colors.red.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Out", style: TextStyle(fontSize: 10, color: textSecondary)),
                                Text(_endAddress.isNotEmpty ? _endAddress : "N/A", style: TextStyle(fontSize: 11, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (widget.record.projectEntries.isNotEmpty) ...[
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100, thickness: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: (isDark ? Colors.white : const Color(0xFF0D6EFD)).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AttendanceLogsDialog(
                        record: widget.record,
                        entryStartAddresses: _entryStartAddresses,
                        entryEndAddresses: _entryEndAddresses,
                      ),
                    );
                  },
                  icon: Icon(IconlyLight.document, size: 16, color: isDark ? Colors.white : const Color(0xFF0D6EFD)),
                  label: Text("View Log", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0D6EFD))),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}