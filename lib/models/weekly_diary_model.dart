class WeeklyDiaryDay {
  final String label;
  final String date;
  final int? submissionId;
  final String? status;
  final String? statusLabel;

  WeeklyDiaryDay({
    required this.label,
    required this.date,
    this.submissionId,
    this.status,
    this.statusLabel,
  });

  bool get isFilled => submissionId != null;

  factory WeeklyDiaryDay.fromJson(Map<String, dynamic> json) {
    return WeeklyDiaryDay(
      label: json['label'] ?? '',
      date: json['date'] ?? '',
      submissionId: json['submission_id'],
      status: json['status'],
      statusLabel: json['status_label'],
    );
  }
}

class WeeklyDiaryRow {
  final int? operativeId;
  final String operative;
  final int? projectId;
  final String project;
  final String client;
  final List<WeeklyDiaryDay> days;
  final int submittedCount;
  final int approvedCount;
  final String status;
  final String statusLabel;

  WeeklyDiaryRow({
    this.operativeId,
    required this.operative,
    this.projectId,
    required this.project,
    required this.client,
    required this.days,
    required this.submittedCount,
    required this.approvedCount,
    required this.status,
    required this.statusLabel,
  });

  factory WeeklyDiaryRow.fromJson(Map<String, dynamic> json) {
    return WeeklyDiaryRow(
      operativeId: json['operative_id'],
      operative: json['operative'] ?? '-',
      projectId: json['project_id'],
      project: json['project'] ?? '-',
      client: json['client'] ?? '-',
      days: (json['days'] as List<dynamic>? ?? [])
          .map((d) => WeeklyDiaryDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      submittedCount: json['submitted_count'] ?? 0,
      approvedCount: json['approved_count'] ?? 0,
      status: json['status'] ?? 'in_progress',
      statusLabel: json['status_label'] ?? 'In Progress',
    );
  }
}

class WeeklyDiaryResponse {
  final String weekStart;
  final String weekEnd;
  final String prevWeek;
  final String nextWeek;
  final List<WeeklyDiaryRow> rows;

  WeeklyDiaryResponse({
    required this.weekStart,
    required this.weekEnd,
    required this.prevWeek,
    required this.nextWeek,
    required this.rows,
  });

  factory WeeklyDiaryResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyDiaryResponse(
      weekStart: json['week_start'] ?? '',
      weekEnd: json['week_end'] ?? '',
      prevWeek: json['prev_week'] ?? '',
      nextWeek: json['next_week'] ?? '',
      rows: (json['rows'] as List<dynamic>? ?? [])
          .map((r) => WeeklyDiaryRow.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
