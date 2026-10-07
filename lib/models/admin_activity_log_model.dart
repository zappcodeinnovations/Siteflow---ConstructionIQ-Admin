class ActivityLogKPI {
  final int totalManagers;
  final int activeManagers;
  final int todayActivities;
  final int thisMonth;
  final int failedLogins;

  final int totalLogs;
  final int todayLogins;
  final int todayCreates;
  final int todayErrors;
  final int uniqueUsersToday;

  ActivityLogKPI({
    required this.totalManagers,
    required this.activeManagers,
    required this.todayActivities,
    required this.thisMonth,
    required this.failedLogins,
    this.totalLogs = 0,
    this.todayLogins = 0,
    this.todayCreates = 0,
    this.todayErrors = 0,
    this.uniqueUsersToday = 0,
  });

  factory ActivityLogKPI.fromJson(Map<String, dynamic> json) {
    int parseVal(List<String> keys, [int defaultVal = 0]) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) {
          final v = json[k];
          if (v is int) return v;
          if (v is num) return v.toInt();
          final parsed = int.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
      return defaultVal;
    }

    final totalManagers = parseVal([
      'total_managers',
      'total_users',
      'managers_count',
      'total_manager_count',
      'managers',
      'users_count',
    ], 0);

    final activeManagers = parseVal([
      'active_managers',
      'active_users',
      'active_manager_count',
      'active_count',
    ], 0);

    final todayActivities = parseVal([
      'todays_activities',
      'today_activities',
      'today_activity_count',
      'activities_today',
      'today_logs',
      'total_today',
    ], 0);

    final thisMonth = parseVal([
      'this_month',
      'month_activities',
      'this_month_activities',
      'monthly_activities',
      'total_this_month',
      'month_logs',
    ], 0);

    final failedLogins = parseVal([
      'failed_logins',
      'today_failed_logins',
      'failed_login_count',
      'failed_logins_count',
      'today_errors',
    ], 0);

    final totalLogs = parseVal(['total_logs', 'total'], 0);
    final todayLogins = parseVal(['today_logins', 'logins_today'], 0);
    final todayCreates = parseVal(['today_creates', 'creates_today'], 0);
    final todayErrors = parseVal(['today_errors', 'errors_today'], 0);
    final uniqueUsersToday = parseVal(['unique_users_today', 'unique_users'], 0);

    return ActivityLogKPI(
      totalManagers: totalManagers > 0 ? totalManagers : (uniqueUsersToday > 0 ? uniqueUsersToday : totalLogs),
      activeManagers: activeManagers > 0 ? activeManagers : (uniqueUsersToday > 0 ? uniqueUsersToday : (totalManagers > 0 ? totalManagers : 0)),
      todayActivities: todayActivities > 0 ? todayActivities : (todayLogins + todayCreates + todayErrors),
      thisMonth: thisMonth > 0 ? thisMonth : (todayActivities > 0 ? todayActivities : totalLogs),
      failedLogins: failedLogins,
      totalLogs: totalLogs,
      todayLogins: todayLogins,
      todayCreates: todayCreates,
      todayErrors: todayErrors,
      uniqueUsersToday: uniqueUsersToday,
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
