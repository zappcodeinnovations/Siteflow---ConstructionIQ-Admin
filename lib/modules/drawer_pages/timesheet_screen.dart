import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/download_manager.dart';
import '../../core/network/api_endpoints.dart';
import 'timesheet_controller.dart';
import 'add_attendance_dialog.dart';
import 'attendance_logs_dialog.dart';
import '../../models/timesheet_model.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final TimesheetController _controller = TimesheetController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    _controller.fetchTimesheets();
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.position.extentAfter < 400) _controller.loadMore();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked =
        await CustomDatePickerDialog.showCustomDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
    if (picked != null) {
      final startStr =
          "${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}";
      final endStr =
          "${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}";
      _controller.setDateRange(startStr, endStr);
      _controller.fetchTimesheets();
    }
  }

  Future<void> _downloadReport() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Downloading report...")));
      }

      final baseUrl = '${ApiEndpoints.baseUrl}/timesheets/export/?';

      List<String> queryParams = [];
      if (_controller.fromDate != null && _controller.fromDate!.isNotEmpty)
        queryParams.add('from=${_controller.fromDate}');
      if (_controller.toDate != null && _controller.toDate!.isNotEmpty)
        queryParams.add('to=${_controller.toDate}');
      if (_controller.selectedOperator != null &&
          _controller.selectedOperator!.isNotEmpty)
        queryParams.add('operator=${_controller.selectedOperator}');
      if (_controller.selectedProject != null &&
          _controller.selectedProject!.isNotEmpty)
        queryParams.add('project=${_controller.selectedProject}');
      if (_controller.selectedAttendanceStatus != null &&
          _controller.selectedAttendanceStatus!.isNotEmpty)
        queryParams.add(
          'attendance_status=${_controller.selectedAttendanceStatus}',
        );
      if (_controller.selectedShiftRule != null &&
          _controller.selectedShiftRule!.isNotEmpty)
        queryParams.add('shift_rule=${_controller.selectedShiftRule}');

      final finalUrl = queryParams.isEmpty
          ? baseUrl.replaceAll('/?', '/')
          : '$baseUrl${queryParams.join('&')}';

      await DownloadManager.instance.downloadUrl(
        url: finalUrl,
        fileName:
            'timesheets_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showAdvancedFilterDialog() {
    if (_controller.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please wait for data to load before filtering."),
        ),
      );
      return;
    }

    final options = _controller.data!.filterOptions;
    final operators =
        (options['operators'] as List?)
            ?.map((e) => e['id'].toString() + "|" + e['name'].toString())
            .toList() ??
        [];
    final projects =
        (options['projects'] as List?)
            ?.map((e) => e['id'].toString() + "|" + e['name'].toString())
            .toList() ??
        [];
    final attendanceChoices =
        (options['attendance_status_choices'] as List?)
            ?.map((e) => e['value'].toString() + "|" + e['label'].toString())
            .toList() ??
        [];
    final shiftChoices =
        (options['shift_rule_choices'] as List?)
            ?.map((e) => e['value'].toString() + "|" + e['label'].toString())
            .toList() ??
        [];

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
            final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final iconBgColor = isDark ? Colors.white24 : Colors.grey.shade100;
            final iconColor = isDark ? Colors.white : Colors.black54;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconlyLight.close_square,
                                size: 18,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildPremiumDropdown(context, "Operator", tempOp, [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Operators"),
                        ),
                        ...operators.map((o) {
                          final parts = o.split('|');
                          return DropdownMenuItem(
                            value: parts[0],
                            child: Text(
                              parts.length > 1 ? parts[1] : parts[0],
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ], (val) => setState(() => tempOp = val)),
                      const SizedBox(height: 16),
                      _buildPremiumDropdown(context, "Project", tempProj, [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Projects"),
                        ),
                        ...projects.map((p) {
                          final parts = p.split('|');
                          return DropdownMenuItem(
                            value: parts[0],
                            child: Text(
                              parts.length > 1 ? parts[1] : parts[0],
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ], (val) => setState(() => tempProj = val)),
                      const SizedBox(height: 16),
                      _buildPremiumDropdown(
                        context,
                        "Attendance Status",
                        tempAtt,
                        [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("All"),
                          ),
                          ...attendanceChoices.map((a) {
                            final parts = a.split('|');
                            return DropdownMenuItem(
                              value: parts[0],
                              child: Text(
                                parts.length > 1 ? parts[1] : parts[0],
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        (val) => setState(() => tempAtt = val),
                      ),
                      const SizedBox(height: 16),
                      _buildPremiumDropdown(context, "Shift Rule", tempShift, [
                        const DropdownMenuItem(value: null, child: Text("All")),
                        ...shiftChoices.map((s) {
                          final parts = s.split('|');
                          return DropdownMenuItem(
                            value: parts[0],
                            child: Text(
                              parts.length > 1 ? parts[1] : parts[0],
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ], (val) => setState(() => tempShift = val)),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                              child: Text(
                                "Clear All",
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                _controller.setAdvancedFilters(
                                  op: tempOp,
                                  project: tempProj,
                                  status: tempAtt,
                                  shift: tempShift,
                                );
                                _controller.fetchTimesheets();
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Apply Filters",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumDropdown(
    BuildContext context,
    String label,
    String? currentValue,
    List<DropdownMenuItem<String>> items,
    Function(String?) onChanged,
  ) {
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
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
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
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : color.withValues(alpha: 0.3);
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          "Timesheets",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.filter),
            onPressed: _showAdvancedFilterDialog,
          ),
          IconButton(
            icon: const Icon(IconlyLight.download),
            onPressed: _downloadReport,
          ),
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
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Date Selector and Refresh
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () => _selectDateRange(context),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IconlyLight.calendar,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        "${_controller.fromDate ?? 'Select'} - ${_controller.toDate ?? 'Date'}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      IconlyLight.arrow_down_2,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.blue.shade300
                                  : const Color(0xFF0D6EFD),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              _controller.resetFilters();
                              _controller.fetchTimesheets();
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text(
                              "Reset",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // KPI Grid
                      if (_controller.data?.kpi != null)
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildKpiCard(
                              "Operators",
                              _controller.data!.kpi!.operators.toString(),
                              const Color(0xFF0D6EFD),
                              IconlyLight.category,
                            ),
                            _buildKpiCard(
                              "Records",
                              _controller.data!.kpi!.records.toString(),
                              Colors.grey.shade700,
                              IconlyLight.paper,
                            ),
                            _buildKpiCard(
                              "Hrs Worked",
                              _controller.data!.kpi!.completedHours,
                              Colors.black87,
                              IconlyLight.time_circle,
                            ),
                            _buildKpiCard(
                              "Clocked In",
                              _controller.data!.kpi!.clockedIn.toString(),
                              Colors.green,
                              IconlyLight.category,
                            ),
                            _buildKpiCard(
                              "Absent",
                              _controller.data!.kpi!.notClockedIn.toString(),
                              Colors.red,
                              IconlyLight.category,
                            ),
                            _buildKpiCard(
                              "Pending",
                              _controller.data!.kpi!.notClockedOut.toString(),
                              Colors.orange,
                              IconlyLight.category,
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      Text(
                        "Recent Records",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_controller.isLoading && _controller.data == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_controller.errorMessage != null &&
                          _controller.data == null)
                        Center(
                          child: Text(
                            _controller.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else if (_controller.data != null)
                        Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _controller.data!.data.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) => _TimesheetCard(
                                record: _controller.data!.data[index],
                                index: index,
                                controller: _controller,
                              ),
                            ),
                            if (_controller.isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              )
                            else if (_controller.hasMore)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Scroll to load more records'),
                              ),
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
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4.0, right: 2.0),
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF0D6EFD),
            tooltip: "Add Attendance",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddAttendanceDialog(controller: _controller),
              );
            },
            child: const Icon(IconlyLight.plus, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _TimesheetCard extends StatefulWidget {
  final TimesheetRecord record;
  final int index;
  final TimesheetController controller;
  const _TimesheetCard({
    required this.record,
    required this.index,
    required this.controller,
  });

  @override
  State<_TimesheetCard> createState() => _TimesheetCardState();
}

class _TimesheetCardState extends State<_TimesheetCard> {
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
    _startAddress = await _getAddressFromCoordinates(
      widget.record.startLocation,
    );
    _endAddress = await _getAddressFromCoordinates(widget.record.endLocation);

    for (int i = 0; i < widget.record.projectEntries.length; i++) {
      final entry = widget.record.projectEntries[i];
      _entryStartAddresses[i] = await _getAddressFromCoordinates(
        entry.startLocation,
      );
      _entryEndAddresses[i] = await _getAddressFromCoordinates(
        entry.endLocation,
      );
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
          final placemarks = await Geocoding().placemarkFromCoordinates(
            lat,
            lng,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            List<String> addressParts = [];
            if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
            if (p.street != null && p.street!.isNotEmpty && p.street != p.name)
              addressParts.add(p.street!);
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              addressParts.add(p.subLocality!);
            if (p.locality != null && p.locality!.isNotEmpty)
              addressParts.add(p.locality!);
            if (p.subAdministrativeArea != null &&
                p.subAdministrativeArea!.isNotEmpty)
              addressParts.add(p.subAdministrativeArea!);
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              addressParts.add(p.administrativeArea!);
            if (p.country != null && p.country!.isNotEmpty)
              addressParts.add(p.country!);
            if (p.postalCode != null && p.postalCode!.isNotEmpty)
              addressParts.add(p.postalCode!);

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

  void _showClockOutDialog(BuildContext context) {
    int? sessionId = widget.record.activeSessionId;
    if (sessionId == null) {
      for (final e in widget.record.projectEntries) {
        if (e.isOpenSession && e.sessionId != null) {
          sessionId = e.sessionId;
          break;
        }
      }
    }

    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to find active session ID to clock out."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupervisorClockOutDialog(
        record: widget.record,
        sessionId: sessionId!,
        controller: widget.controller,
      ),
    );
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

    final avatarColors = [
      const Color(0xFF0D6EFD),
      const Color(0xFF0F172A),
      const Color(0xFFD4AF37),
    ];
    final aColor = avatarColors[widget.index % avatarColors.length];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: aColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.record.operatorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "OP-${widget.record.operatorCode}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IconlyLight.category, size: 9, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade100,
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          IconlyLight.calendar,
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.record.date.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.record.shiftHours.trim().isNotEmpty
                              ? "${widget.record.shiftHours.trim()} hrs"
                              : (widget.record.attendanceState ==
                                        'clocked_in' ||
                                    widget.record.clockOut.trim().isEmpty)
                              ? "In Progress"
                              : "-",
                          style: TextStyle(
                            fontSize: widget.record.shiftHours.trim().isNotEmpty
                                ? 15
                                : 12,
                            fontWeight: FontWeight.bold,
                            color: widget.record.shiftHours.trim().isNotEmpty
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF0D6EFD))
                                : (widget.record.attendanceState ==
                                          'clocked_in' ||
                                      widget.record.clockOut.trim().isEmpty)
                                ? Colors.green
                                : textSecondary,
                          ),
                        ),
                        Text(
                          "Total Duration",
                          style: TextStyle(fontSize: 10, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.record.projectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (widget.record.projectCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Project Code: ${widget.record.projectCode}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      IconlyLight.time_circle,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.record.clockOut.trim().isNotEmpty
                            ? "${widget.record.clockIn} - ${widget.record.clockOut}"
                            : "${widget.record.clockIn} - Active",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                      ),
                    ),
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
                          Icon(
                            IconlyLight.location,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "In",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textSecondary,
                                  ),
                                ),
                                Text(
                                  _startAddress.isNotEmpty
                                      ? _startAddress
                                      : "N/A",
                                  style: TextStyle(
                                    fontSize: 11,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            IconlyLight.location,
                            size: 14,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Out",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textSecondary,
                                  ),
                                ),
                                Text(
                                  _endAddress.isNotEmpty ? _endAddress : (widget.record.isOpenSession ? "Active Session" : "N/A"),
                                  style: TextStyle(
                                    fontSize: 11,
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
                ),
              ],
            ),
          ),

          if (widget.record.isOpenSession || widget.record.projectEntries.isNotEmpty) ...[
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.grey.shade100,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  if (widget.record.projectEntries.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        backgroundColor:
                            (isDark ? Colors.white : const Color(0xFF0D6EFD))
                                .withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                      icon: Icon(
                        IconlyLight.document,
                        size: 16,
                        color: isDark ? Colors.white : const Color(0xFF0D6EFD),
                      ),
                      label: Text(
                        "View Log",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0D6EFD),
                        ),
                      ),
                    ),
                  if (widget.record.isOpenSession && widget.record.projectEntries.isNotEmpty)
                    const SizedBox(width: 10),
                  if (widget.record.isOpenSession)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _showClockOutDialog(context),
                        icon: const Icon(IconlyLight.time_circle, size: 16, color: Colors.white),
                        label: const Text(
                          "Clock Out Operative",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SupervisorClockOutDialog extends StatefulWidget {
  final TimesheetRecord record;
  final int sessionId;
  final TimesheetController controller;

  const SupervisorClockOutDialog({
    super.key,
    required this.record,
    required this.sessionId,
    required this.controller,
  });

  @override
  State<SupervisorClockOutDialog> createState() => _SupervisorClockOutDialogState();
}

class _SupervisorClockOutDialogState extends State<SupervisorClockOutDialog> {
  final TextEditingController _workPerformedController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  double? _acquiredLat;
  double? _acquiredLon;
  bool _isAcquiringLocation = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _workPerformedController.dispose();
    _workLocationController.dispose();
    _commentsController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isAcquiringLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled on your device.")),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission is required to acquire current location.")),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _acquiredLat = pos.latitude;
        _acquiredLon = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Location acquired: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error acquiring location: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isAcquiringLocation = false);
    }
  }

  Future<void> _handleSubmit() async {
    final work = _workPerformedController.text.trim();
    final sig = _signatureController.text.trim();

    if (work.isEmpty) {
      setState(() => _errorMessage = "Work Performed is required.");
      return;
    }
    if (sig.isEmpty) {
      setState(() => _errorMessage = "Text Signature is required.");
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    final res = await widget.controller.clockOutSession(
      widget.sessionId,
      workPerformed: work,
      signatureText: sig,
      workLocation: _workLocationController.text.trim(),
      comments: _commentsController.text.trim(),
      latitude: _acquiredLat,
      longitude: _acquiredLon,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Operative clocked out successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to clock out operative.';
      });
    }
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black87;
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: labelColor,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hintText,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            filled: true,
            fillColor: boxBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: screenHeight - keyboardHeight - 48,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(IconlyLight.time_circle, color: Colors.orange.shade700, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Complete Daily Diary & Clock Out",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconlyLight.close_square,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info banner for Operative & Project
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2E40) : Colors.orange.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(IconlyLight.profile, color: Colors.orange.shade800, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${widget.record.operatorName}${widget.record.projectName.isNotEmpty ? " • ${widget.record.projectName}" : ""}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.orange.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(IconlyLight.danger, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          "Work Performed",
                          _workPerformedController,
                          maxLines: 4,
                          hintText: "Describe the work completed during this shift",
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Work Location",
                          _workLocationController,
                          hintText: "e.g. Floor 2, Grid line A-C",
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Comments",
                          _commentsController,
                          maxLines: 3,
                          hintText: "Additional notes or remarks",
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Text Signature",
                          _signatureController,
                          hintText: "Type the operative's signature name",
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),

                        // Location Button & Status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _acquiredLat != null
                                      ? Colors.green
                                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: _isAcquiringLocation ? null : _getCurrentLocation,
                              icon: _isAcquiringLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      IconlyLight.location,
                                      size: 16,
                                      color: _acquiredLat != null
                                          ? Colors.green
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                              label: Text(
                                _acquiredLat != null
                                    ? "Location: ${_acquiredLat!.toStringAsFixed(4)}, ${_acquiredLon!.toStringAsFixed(4)}"
                                    : "Use Current Location",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _acquiredLat != null
                                      ? Colors.green
                                      : (isDark ? Colors.white : Colors.black87),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _acquiredLat != null
                                  ? "Current location added."
                                  : "Current location is required for clock out.",
                              style: TextStyle(
                                fontSize: 12,
                                color: _acquiredLat != null
                                    ? Colors.green.shade700
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  "Save Diary & Clock Out",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
