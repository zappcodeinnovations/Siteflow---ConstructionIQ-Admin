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
    final managerName = json['user_name'] ?? json['user']?['name'] ?? json['user']?.toString() ?? 'Unknown';
    
    final moduleName = json['module_name'] ?? json['module'] ?? '';
    final moduleSub = json['record_id']?.toString() ?? '';

    // Format date and time
    final createdAt = json['timestamp'] ?? json['created_at'] ?? '';
    String date = '';
    String time = '';
    try {
      if (createdAt.toString().isNotEmpty) {
        final dt = DateTime.parse(createdAt.toString()).toLocal();
        date = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
        time = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
      }
    } catch (_) {
      date = createdAt.toString();
    }

    // JSON diff stringification
    String beforeStr = '-';
    String afterStr = '-';
    final changeSummary = json['change_summary'];
    if (changeSummary is Map) {
      beforeStr = changeSummary['previous']?.toString() ?? '-';
      afterStr = changeSummary['new']?.toString() ?? '-';
    } else if (changeSummary is String && changeSummary.isNotEmpty) {
      afterStr = changeSummary;
    }

    final idVal = json['id'];
    final id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '0') ?? 0;

    return ActivityLog(
      id: id,
      managerName: managerName.toString(),
      module: moduleName.toString(),
      moduleDetail: moduleSub.isNotEmpty ? 'Record ID: $moduleSub' : '',
      action: (json['action_type'] ?? json['action'] ?? 'Unknown').toString(),
      beforeState: beforeStr,
      afterState: afterStr,
      whenDate: date,
      whenTime: time,
    );
  }
}
