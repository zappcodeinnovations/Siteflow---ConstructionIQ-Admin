import 'dart:convert';
import 'project_model.dart';
import 'user_model.dart';

class DashboardData {
  final String today;
  final User? user;
  final Kpis? kpis;
  final List<Project> recentProjects;
  final List<dynamic> recentTasks;
  final List<dynamic> recentJobSheets;
  final List<dynamic> recentClockSessions;

  DashboardData({
    required this.today,
    this.user,
    this.kpis,
    this.recentProjects = const [],
    this.recentTasks = const [],
    this.recentJobSheets = const [],
    this.recentClockSessions = const [],
  });

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  factory DashboardData.fromJson(dynamic jsonInput) {
    final Map<String, dynamic> json = _parseMap(jsonInput);
    return DashboardData(
      today: json['today'] ?? '',
      user: json['user'] != null ? User.fromJson(_parseMap(json['user'])) : null,
      kpis: json['kpis'] != null ? Kpis.fromJson(_parseMap(json['kpis'])) : null,
      recentProjects: json['recent_projects'] != null && json['recent_projects'] is List
          ? (json['recent_projects'] as List).map((i) => Project.fromJson(_parseMap(i))).toList()
          : [],
      recentTasks: json['recent_tasks'] is List ? json['recent_tasks'] : [],
      recentJobSheets: json['recent_job_sheets'] is List ? json['recent_job_sheets'] : [],
      recentClockSessions: json['recent_clock_sessions'] is List ? json['recent_clock_sessions'] : [],
    );
  }
}

class Kpis {
  final Map<String, dynamic> clients;
  final Map<String, dynamic> projects;
  final Map<String, dynamic> tasks;
  final Map<String, dynamic> jobSheets;
  final Map<String, dynamic> attendance;
  final Map<String, dynamic> users;

  Kpis({
    required this.clients,
    required this.projects,
    required this.tasks,
    required this.jobSheets,
    required this.attendance,
    required this.users,
  });

  factory Kpis.fromJson(dynamic jsonInput) {
    final Map<String, dynamic> json = DashboardData._parseMap(jsonInput);
    return Kpis(
      clients: DashboardData._parseMap(json['clients']),
      projects: DashboardData._parseMap(json['projects']),
      tasks: DashboardData._parseMap(json['tasks']),
      jobSheets: DashboardData._parseMap(json['job_sheets']),
      attendance: DashboardData._parseMap(json['attendance']),
      users: DashboardData._parseMap(json['users']),
    );
  }
}
