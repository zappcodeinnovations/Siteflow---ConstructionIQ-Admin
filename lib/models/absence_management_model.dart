class AbsenceSummary {
  final int totalRequests;
  final int pendingRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int absentToday;
  final int upcomingAbsences;

  const AbsenceSummary({
    this.totalRequests = 0,
    this.pendingRequests = 0,
    this.approvedRequests = 0,
    this.rejectedRequests = 0,
    this.absentToday = 0,
    this.upcomingAbsences = 0,
  });

  factory AbsenceSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AbsenceSummary();
    int parseVal(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return AbsenceSummary(
      totalRequests: parseVal(json['total_requests']),
      pendingRequests: parseVal(json['pending_requests']),
      approvedRequests: parseVal(json['approved_requests']),
      rejectedRequests: parseVal(json['rejected_requests']),
      absentToday: parseVal(json['absent_today']),
      upcomingAbsences: parseVal(json['upcoming_absences']),
    );
  }
}

class AbsenceRecord {
  final int id;
  final int operativeId;
  final String operativeName;
  final String operativeEmployeeId;
  final int? projectId;
  final String projectName;
  final String absenceType;
  final String absenceTypeLabel;
  final String reason;
  final String startDate;
  final String endDate;
  final int durationDays;
  final String durationLabel;
  final bool isPartialDay;
  final String notes;
  final String status;
  final String statusLabel;
  final String recordedByName;
  final String updatedByName;
  final String createdAt;
  final String updatedAt;

  AbsenceRecord({
    required this.id,
    required this.operativeId,
    required this.operativeName,
    required this.operativeEmployeeId,
    this.projectId,
    required this.projectName,
    required this.absenceType,
    required this.absenceTypeLabel,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.durationLabel,
    required this.isPartialDay,
    required this.notes,
    required this.status,
    required this.statusLabel,
    required this.recordedByName,
    required this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AbsenceRecord.fromJson(Map<String, dynamic> json) {
    final op = json['operative'] as Map<String, dynamic>?;
    final proj = json['project'] as Map<String, dynamic>?;

    final id = json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0;
    final opId = json['operative_id'] is int
        ? json['operative_id'] as int
        : (op?['id'] is int ? op!['id'] as int : int.tryParse('${op?['id'] ?? json['operative_id']}') ?? 0);

    final pId = json['project_id'] is int
        ? json['project_id'] as int
        : (proj?['id'] is int ? proj!['id'] as int : int.tryParse('${proj?['id'] ?? json['project_id']}'));

    final diff = json['duration_days'] is int
        ? json['duration_days'] as int
        : int.tryParse('${json['duration_days']}') ?? 1;

    return AbsenceRecord(
      id: id,
      operativeId: opId,
      operativeName: json['operative_name']?.toString() ?? op?['name']?.toString() ?? '-',
      operativeEmployeeId: op?['employee_id']?.toString() ?? '',
      projectId: pId,
      projectName: json['project_name']?.toString() ?? proj?['name']?.toString() ?? 'General / Company-wide',
      absenceType: json['absence_type']?.toString() ?? 'other',
      absenceTypeLabel: json['absence_type_display']?.toString() ??
          json['absence_type_label']?.toString() ??
          'Other',
      reason: json['reason']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      durationDays: diff,
      durationLabel: json['duration_label']?.toString() ?? '$diff Day${diff > 1 ? 's' : ''}',
      isPartialDay: json['is_partial_day'] == true || '${json['is_partial_day']}'.toLowerCase() == 'true',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_display']?.toString() ??
          json['status_label']?.toString() ??
          'Pending',
      recordedByName: json['recorded_by_name']?.toString() ?? json['recorded_by']?.toString() ?? '',
      updatedByName: json['updated_by_name']?.toString() ?? json['updated_by']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Extracts clean rejection reason from notes if present
  String? get rejectionReason {
    if (!notes.contains('[Rejection Reason:')) return null;
    final start = notes.indexOf('[Rejection Reason:') + 18;
    final end = notes.indexOf(']', start);
    if (end != -1) {
      return notes.substring(start, end).trim();
    }
    return notes.substring(start).trim();
  }
}

class AbsenceFilterOptions {
  final List<Map<String, dynamic>> absenceTypes;
  final List<Map<String, dynamic>> statuses;
  final List<Map<String, dynamic>> operatives;
  final List<Map<String, dynamic>> projects;

  const AbsenceFilterOptions({
    this.absenceTypes = const [],
    this.statuses = const [],
    this.operatives = const [],
    this.projects = const [],
  });

  factory AbsenceFilterOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AbsenceFilterOptions();
    return AbsenceFilterOptions(
      absenceTypes: List<Map<String, dynamic>>.from(json['absence_types'] ?? const []),
      statuses: List<Map<String, dynamic>>.from(json['statuses'] ?? const []),
      operatives: List<Map<String, dynamic>>.from(json['operatives'] ?? const []),
      projects: List<Map<String, dynamic>>.from(json['projects'] ?? const []),
    );
  }
}
