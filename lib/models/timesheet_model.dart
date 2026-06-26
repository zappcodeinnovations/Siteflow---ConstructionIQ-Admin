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

  ProjectEntry({
    required this.projectName,
    required this.projectCode,
    required this.clockInTime,
    required this.clockOutTime,
    required this.shiftHours,
    required this.startLocation,
    required this.endLocation,
    required this.notes,
  });

  factory ProjectEntry.fromJson(Map<String, dynamic> json) {
    return ProjectEntry(
      projectName: json['project_name'] ?? '',
      projectCode: json['project_code'] ?? '',
      clockInTime: json['clock_in_time'] ?? '',
      clockOutTime: json['clock_out_time'] ?? '',
      shiftHours: json['shift_hours'] ?? '',
      startLocation: json['start_location'] ?? '',
      endLocation: json['end_location'] ?? '',
      notes: json['notes'] ?? '',
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
    required this.projectEntries,
  });

  factory TimesheetRecord.fromJson(Map<String, dynamic> json) {
    var entriesList = json['project_entries'] as List? ?? [];
    return TimesheetRecord(
      operatorName: json['operator_name'] ?? '',
      operatorCode: json['operator_code'] ?? '',
      projectName: json['project_name'] ?? '',
      projectCode: json['project_code'] ?? '',
      date: json['date'] ?? '',
      clockIn: json['clock_in'] ?? '',
      clockOut: json['clock_out'] ?? '',
      shiftHours: json['shift_hours'] ?? '',
      startLocation: json['start_location'] ?? '',
      endLocation: json['end_location'] ?? '',
      attendanceState: json['attendance_state'] ?? '',
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
