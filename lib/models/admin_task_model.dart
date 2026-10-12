class AdminTaskModel {
  final int id;
  final String taskNo;
  final String taskDisplayNo;
  final String reference;
  final String status;
  final String statusLabel;
  final int projectId;
  final String projectName;
  final String clientName;
  final String operativeName;
  final String formName;
  final int sheetCount;
  final String? scheduledDate;
  final String? createdAt;

  const AdminTaskModel({
    required this.id,
    required this.taskNo,
    required this.taskDisplayNo,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.projectId,
    required this.projectName,
    required this.clientName,
    required this.operativeName,
    required this.formName,
    required this.sheetCount,
    required this.scheduledDate,
    required this.createdAt,
  });

  factory AdminTaskModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

    return AdminTaskModel(
      id: parseInt(json['id']),
      taskNo: json['task_no']?.toString() ?? '',
      taskDisplayNo: json['task_display_no']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      projectId: parseInt(json['project_id']),
      projectName: json['project_name']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      operativeName: json['operative_name']?.toString() ?? '',
      formName: json['form_name']?.toString() ?? '',
      sheetCount: parseInt(json['sheet_count']),
      scheduledDate: json['scheduled_date']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
