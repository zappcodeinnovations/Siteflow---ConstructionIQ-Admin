class ManagerAttendanceKPI {
  final int entries;
  final String completedHours;
  final String currentStatus;
  final String? clockedInSince;

  ManagerAttendanceKPI({
    required this.entries,
    required this.completedHours,
    required this.currentStatus,
    this.clockedInSince,
  });

  factory ManagerAttendanceKPI.fromJson(Map<String, dynamic> json) {
    return ManagerAttendanceKPI(
      entries: json['entries'] ?? 0,
      completedHours: json['completed_hours'] ?? "00:00",
      currentStatus: json['current_status'] ?? "Clocked Out",
      clockedInSince: json['clocked_in_since'],
    );
  }
}

class ManagerAttendanceLogEntry {
  final String date;
  final String clockIn;
  final String clockOut;
  final String hours;
  final String startLocation;
  final String endLocation;
  final String notes;
  final bool isOpen;

  ManagerAttendanceLogEntry({
    required this.date,
    required this.clockIn,
    required this.clockOut,
    required this.hours,
    required this.startLocation,
    required this.endLocation,
    required this.notes,
    required this.isOpen,
  });

  factory ManagerAttendanceLogEntry.fromJson(Map<String, dynamic> json) {
    return ManagerAttendanceLogEntry(
      date: json['date'] ?? '',
      clockIn: json['clock_in'] ?? '',
      clockOut: json['clock_out'] ?? '',
      hours: json['hours'] ?? '',
      startLocation: json['start_location'] ?? '',
      endLocation: json['end_location'] ?? '',
      notes: json['notes'] ?? '',
      isOpen: json['is_open'] ?? false,
    );
  }
}

class ManagerAttendanceRecord {
  final String managerName;
  final String managerCode;
  final String role;
  final String date;
  final String clockIn;
  final String clockOut;
  final String hours;
  final String startLocation;
  final String endLocation;
  final bool isOpenSession;
  final int logEntriesCount;
  final String summaryFirstLogin;
  final String summaryLastLogout;
  final String summaryTotalWorked;
  final int summaryLogCount;
  final List<ManagerAttendanceLogEntry> logEntries;

  ManagerAttendanceRecord({
    required this.managerName,
    required this.managerCode,
    required this.role,
    required this.date,
    required this.clockIn,
    required this.clockOut,
    required this.hours,
    required this.startLocation,
    required this.endLocation,
    required this.isOpenSession,
    required this.logEntriesCount,
    required this.summaryFirstLogin,
    required this.summaryLastLogout,
    required this.summaryTotalWorked,
    required this.summaryLogCount,
    required this.logEntries,
  });

  factory ManagerAttendanceRecord.fromJson(Map<String, dynamic> json) {
    var entriesList = json['log_entries'] as List? ?? [];
    return ManagerAttendanceRecord(
      managerName: json['manager_name'] ?? '',
      managerCode: json['manager_code'] ?? '',
      role: json['role'] ?? '',
      date: json['date'] ?? '',
      clockIn: json['clock_in'] ?? '',
      clockOut: json['clock_out'] ?? '',
      hours: json['hours'] ?? '',
      startLocation: json['start_location'] ?? '',
      endLocation: json['end_location'] ?? '',
      isOpenSession: json['is_open_session'] ?? false,
      logEntriesCount: json['log_entries_count'] ?? 0,
      summaryFirstLogin: json['summary_first_login'] ?? '',
      summaryLastLogout: json['summary_last_logout'] ?? '',
      summaryTotalWorked: json['summary_total_worked'] ?? '',
      summaryLogCount: json['summary_log_count'] ?? 0,
      logEntries: entriesList.map((i) => ManagerAttendanceLogEntry.fromJson(i)).toList(),
    );
  }
}

class ManagerAttendanceResponse {
  final bool status;
  final String message;
  final ManagerAttendanceKPI? kpi;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> pagination;
  final List<ManagerAttendanceRecord> data;

  ManagerAttendanceResponse({
    required this.status,
    required this.message,
    this.kpi,
    required this.filters,
    required this.pagination,
    required this.data,
  });

  factory ManagerAttendanceResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return ManagerAttendanceResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      kpi: json['kpi'] != null ? ManagerAttendanceKPI.fromJson(json['kpi']) : null,
      filters: json['filters'] ?? {},
      pagination: json['pagination'] ?? {},
      data: dataList.map((i) => ManagerAttendanceRecord.fromJson(i)).toList(),
    );
  }
}
