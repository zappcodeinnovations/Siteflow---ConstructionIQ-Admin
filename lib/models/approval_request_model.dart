class ApprovalRequestModel {
  final int id;
  final int submissionId;
  final String formName;
  final int projectId;
  final String projectName;
  final String operativeName;
  final int resubmissionCount;
  final bool isRead;
  final String updatedAt;

  ApprovalRequestModel({
    required this.id,
    required this.submissionId,
    required this.formName,
    required this.projectId,
    required this.projectName,
    required this.operativeName,
    required this.resubmissionCount,
    required this.isRead,
    required this.updatedAt,
  });

  factory ApprovalRequestModel.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      submissionId: json['submission_id'] is int ? json['submission_id'] : int.tryParse('${json['submission_id']}') ?? 0,
      formName: json['form_name']?.toString() ?? 'Form submission',
      projectId: json['project_id'] is int ? json['project_id'] : int.tryParse('${json['project_id']}') ?? 0,
      projectName: json['project_name']?.toString() ?? '',
      operativeName: json['operative_name']?.toString() ?? '-',
      resubmissionCount: json['resubmission_count'] is int ? json['resubmission_count'] : int.tryParse('${json['resubmission_count']}') ?? 0,
      isRead: json['is_read'] == true,
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
