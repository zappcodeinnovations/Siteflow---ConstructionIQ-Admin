import 'client_model.dart';

class Project {
  final int id;
  final String name;
  final String code;
  final String description;
  final String status;
  final String priority;
  final String siteAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? latitude;
  final String? longitude;
  final String? startDate;
  final String? endDate;
  final String? budget;
  final int progress;
  final Client? client;
  final Map<String, dynamic>? template;
  final List<dynamic>? selectedTemplates;
  final Map<String, dynamic>? contractor;
  final String statusLabel;
  final String priorityLabel;
  final int assignedWorkerCount;
  final int jobCount;
  final String? qrToken;
  final Map<String, dynamic>? qrPayload;
  final String? createdAt;
  final String? updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.status,
    required this.priority,
    required this.siteAddress,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.startDate,
    this.endDate,
    this.budget,
    required this.progress,
    this.client,
    this.template,
    this.selectedTemplates,
    this.contractor,
    required this.statusLabel,
    required this.priorityLabel,
    required this.assignedWorkerCount,
    required this.jobCount,
    this.qrToken,
    this.qrPayload,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      siteAddress: json['site_address'] ?? '',
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      startDate: json['start_date'],
      endDate: json['end_date'],
      budget: json['budget']?.toString(),
      progress: json['progress'] ?? 0,
      client: json['client'] is Map ? Client.fromJson(Map<String, dynamic>.from(json['client'])) : null,
      template: json['template'] is Map ? Map<String, dynamic>.from(json['template']) : null,
      selectedTemplates: json['selected_templates'] is List ? json['selected_templates'] : null,
      contractor: json['contractor'] is Map ? Map<String, dynamic>.from(json['contractor']) : null,
      statusLabel: json['status_label'] ?? '',
      priorityLabel: json['priority_label'] ?? '',
      assignedWorkerCount: json['assigned_worker_count'] ?? 0,
      jobCount: json['job_count'] ?? 0,
      qrToken: json['qr_token'],
      qrPayload: json['qr_payload'] is Map ? Map<String, dynamic>.from(json['qr_payload']) : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
