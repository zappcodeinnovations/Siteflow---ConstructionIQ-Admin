class ManagerDiaryEntry {
  final int id;
  final int? formId;
  final String formName;
  final String operativeName;
  final String operativeEmail;
  final String status;
  final int fieldCount;
  final int completedFields;
  final int fileCount;
  final String? submittedAt;
  final bool isOwnSubmission;

  ManagerDiaryEntry({
    required this.id,
    this.formId,
    required this.formName,
    required this.operativeName,
    required this.operativeEmail,
    required this.status,
    required this.fieldCount,
    required this.completedFields,
    required this.fileCount,
    this.submittedAt,
    required this.isOwnSubmission,
  });

  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get canEditAndResubmit => isOwnSubmission && isRejected;

  factory ManagerDiaryEntry.fromJson(Map<String, dynamic> json) {
    return ManagerDiaryEntry(
      id: json['id'] ?? 0,
      formId: json['form_id'],
      formName: json['form_name'] ?? '-',
      operativeName: json['operative_name'] ?? '-',
      operativeEmail: json['operative_email'] ?? '-',
      status: json['status'] ?? '',
      fieldCount: json['field_count'] ?? 0,
      completedFields: json['completed_fields'] ?? 0,
      fileCount: json['file_count'] ?? 0,
      submittedAt: json['submitted_at'],
      isOwnSubmission: json['is_own_submission'] ?? false,
    );
  }
}

class ManagerDiaryForm {
  final int id;
  final String name;

  ManagerDiaryForm({required this.id, required this.name});

  factory ManagerDiaryForm.fromJson(Map<String, dynamic> json) {
    return ManagerDiaryForm(id: json['id'] ?? 0, name: json['name'] ?? '-');
  }
}
