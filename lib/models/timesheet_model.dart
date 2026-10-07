class TimesheetKPI {
  final int operators;
  final int records;
  final String completedHours;
  final int clockedIn;
  final int notClockedIn;
  final int notClockedOut;

  TimesheetKPI({
    required this.operators,
    required this.records,
    required this.completedHours,
    required this.clockedIn,
    required this.notClockedIn,
    required this.notClockedOut,
  });

  factory TimesheetKPI.fromJson(Map<String, dynamic> json) {
    return TimesheetKPI(
      operators: json['operators'] ?? 0,
      records: json['records'] ?? 0,
      completedHours: json['completed_hours'] ?? "00:00",
      clockedIn: json['clocked_in'] ?? 0,
      notClockedIn: json['not_clocked_in'] ?? 0,
      notClockedOut: json['not_clocked_out'] ?? 0,
    );
  }
}

class ProjectEntry {
  final String projectName;
  final String projectCode;
  final String clockInTime;
  final String clockOutTime;
  final String shiftHours;
  final String startLocation;
  final String endLocation;
  final String notes;
  final String device;
  final String flags;

  ProjectEntry({
    required this.projectName,
    required this.projectCode,
    required this.clockInTime,
    required this.clockOutTime,
    required this.shiftHours,
    required this.startLocation,
    required this.endLocation,
    required this.notes,
    this.device = '',
    this.flags = '',
  });

  static String _extractString(dynamic val) {
    if (val == null) return '';
    if (val is String) return val.trim();
    if (val is Map) return (val['name'] ?? val['model'] ?? val['title'] ?? val['label'] ?? val['value'] ?? '').toString().trim();
    if (val is List) return val.map((e) => _extractString(e)).where((s) => s.isNotEmpty).join(', ');
    return val.toString().trim();
  }

  factory ProjectEntry.fromJson(Map<String, dynamic> json) {
    return ProjectEntry(
      projectName: _extractString(json['project_name']),
      projectCode: _extractString(json['project_code']),
      clockInTime: _extractString(json['clock_in_time']),
      clockOutTime: _extractString(json['clock_out_time']),
      shiftHours: _extractString(json['shift_hours']),
      startLocation: _extractString(json['start_location']),
      endLocation: _extractString(json['end_location']),
      notes: _extractString(json['notes']),
      device: _extractString(
        json['device'] ??
            json['device_model'] ??
            json['device_name'] ??
            json['device_info'] ??
            json['device_source'] ??
            json['platform'] ??
            json['device_type'] ??
            json['model'],
      ),
      flags: _extractString(
        json['flags'] ??
            json['flag'] ??
            json['validation_flags'] ??
            json['validation_flag'] ??
            json['attendance_flags'] ??
            json['status'],
      ),
    );
  }
}

class TimesheetRecord {
  final String operatorName;
  final String operatorCode;
  final String projectName;
  final String projectCode;
  final String date;
  final String clockIn;
  final String clockOut;
  final String shiftHours;
  final String startLocation;
  final String endLocation;
  final String attendanceState;
  final String device;
  final String flags;
  final List<ProjectEntry> projectEntries;

  TimesheetRecord({
    required this.operatorName,
    required this.operatorCode,
    required this.projectName,
    required this.projectCode,
    required this.date,
    required this.clockIn,
    required this.clockOut,
    required this.shiftHours,
    required this.startLocation,
    required this.endLocation,
    required this.attendanceState,
    this.device = '',
    this.flags = '',
    required this.projectEntries,
  });

  static String _extractString(dynamic val) {
    if (val == null) return '';
    if (val is String) return val.trim();
    if (val is Map) return (val['name'] ?? val['model'] ?? val['title'] ?? val['label'] ?? val['value'] ?? '').toString().trim();
    if (val is List) return val.map((e) => _extractString(e)).where((s) => s.isNotEmpty).join(', ');
    return val.toString().trim();
  }

  factory TimesheetRecord.fromJson(Map<String, dynamic> json) {
    var entriesList = json['project_entries'] as List? ?? [];
    return TimesheetRecord(
      operatorName: _extractString(json['operator_name']),
      operatorCode: _extractString(json['operator_code']),
      projectName: _extractString(json['project_name']),
      projectCode: _extractString(json['project_code']),
      date: _extractString(json['date']),
      clockIn: _extractString(json['clock_in']),
      clockOut: _extractString(json['clock_out']),
      shiftHours: _extractString(json['shift_hours']),
      startLocation: _extractString(json['start_location']),
      endLocation: _extractString(json['end_location']),
      attendanceState: _extractString(json['attendance_state']),
      device: _extractString(
        json['device'] ??
            json['device_model'] ??
            json['device_name'] ??
            json['device_info'] ??
            json['device_source'] ??
            json['platform'] ??
            json['device_type'] ??
            json['model'],
      ),
      flags: _extractString(
        json['flags'] ??
            json['flag'] ??
            json['validation_flags'] ??
            json['validation_flag'] ??
            json['attendance_flags'] ??
            json['status'],
      ),
      projectEntries: entriesList.map((i) => ProjectEntry.fromJson(i)).toList(),
    );
  }
}

class TimesheetResponse {
  final bool status;
  final String message;
  final Map<String, dynamic> filters;
  final TimesheetKPI? kpi;
  final Map<String, dynamic> pagination;
  final Map<String, dynamic> filterOptions;
  final List<TimesheetRecord> data;

  TimesheetResponse({
    required this.status,
    required this.message,
    required this.filters,
    this.kpi,
    required this.pagination,
    required this.filterOptions,
    required this.data,
  });

  factory TimesheetResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return TimesheetResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      filters: json['filters'] ?? {},
      kpi: json['kpi'] != null ? TimesheetKPI.fromJson(json['kpi']) : null,
      pagination: json['pagination'] ?? {},
      filterOptions: json['filter_options'] ?? {},
      data: dataList.map((i) => TimesheetRecord.fromJson(i)).toList(),
    );
  }
}
