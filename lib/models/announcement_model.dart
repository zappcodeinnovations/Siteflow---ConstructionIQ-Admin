class Announcement {
  final int id;
  final int projectId;
  final String projectName;
  final String projectCode;
  final String clientName;
  final String title;
  final String message;
  final bool isActive;
  final String createdByName;
  final String updatedByName;
  final String createdAt;
  final String updatedAt;

  Announcement({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.projectCode,
    required this.clientName,
    required this.title,
    required this.message,
    required this.isActive,
    required this.createdByName,
    required this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      projectId: json['project_id'] ?? 0,
      projectName: json['project_name'] ?? '',
      projectCode: json['project_code'] ?? '',
      clientName: json['client_name'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isActive: json['is_active'] ?? false,
      createdByName: json['created_by_name'] ?? '',
      updatedByName: json['updated_by_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'project_code': projectCode,
      'client_name': clientName,
      'title': title,
      'message': message,
      'is_active': isActive,
      'created_by_name': createdByName,
      'updated_by_name': updatedByName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
