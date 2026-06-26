class ActivityLogKPI {
  final int totalLogs;
  final int todayLogins;
  final int todayCreates;
  final int todayErrors;
  final int uniqueUsersToday;

  ActivityLogKPI({
    required this.totalLogs,
    required this.todayLogins,
    required this.todayCreates,
    required this.todayErrors,
    required this.uniqueUsersToday,
  });

  factory ActivityLogKPI.fromJson(Map<String, dynamic> json) {
    return ActivityLogKPI(
      totalLogs: json['total_logs'] ?? 0,
      todayLogins: json['today_logins'] ?? 0,
      todayCreates: json['today_creates'] ?? 0,
      todayErrors: json['today_errors'] ?? 0,
      uniqueUsersToday: json['unique_users_today'] ?? 0,
    );
  }
}

class ActivityLog {
  final int id;
  final String managerName;
  final String module;
  final String moduleDetail;
  final String action;
  final String beforeState;
  final String afterState;
  final String whenDate;
  final String whenTime;

  ActivityLog({
    required this.id,
    required this.managerName,
    required this.module,
    required this.moduleDetail,
    required this.action,
    required this.beforeState,
    required this.afterState,
    required this.whenDate,
    required this.whenTime,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final managerName = json['user_name'] ?? 'Unknown';
    
    final moduleName = json['module_name'] ?? '';
    final moduleSub = json['record_id']?.toString() ?? '';

    // Format date and time
    final createdAt = json['timestamp'] ?? '';
    String date = '';
    String time = '';
    try {
      if (createdAt.isNotEmpty) {
        final dt = DateTime.parse(createdAt).toLocal();
        date = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
        time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
      }
    } catch (_) {
      date = createdAt;
    }

    // JSON diff stringification
    String beforeStr = '-';
    String afterStr = '-';
    if (json['change_summary'] != null) {
      beforeStr = json['change_summary']['previous']?.toString() ?? '-';
      afterStr = json['change_summary']['new']?.toString() ?? '-';
    }

    return ActivityLog(
      id: json['id'] ?? 0,
      managerName: managerName,
      module: moduleName,
      moduleDetail: moduleSub.isNotEmpty ? 'Record ID: $moduleSub' : '',
      action: json['action_type'] ?? 'Unknown',
      beforeState: beforeStr,
      afterState: afterStr,
      whenDate: date,
      whenTime: time,
    );
  }
}
