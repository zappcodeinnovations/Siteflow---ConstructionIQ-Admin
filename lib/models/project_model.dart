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
  final String? lastActivity;
  final String? lastActivityAt;
  final String? ecgManager;

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
    this.lastActivity,
    this.lastActivityAt,
    this.ecgManager,
  });

  static String formatTimeAgo(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final diff = DateTime.now().difference(dateTime);
      if (diff.inDays >= 7) {
        final weeks = diff.inDays ~/ 7;
        final remainingDays = diff.inDays % 7;
        if (remainingDays > 0) {
          return '$weeks week${weeks > 1 ? 's' : ''}, $remainingDays day${remainingDays > 1 ? 's' : ''} ago';
        }
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else if (diff.inDays > 0) {
        final hours = diff.inHours % 24;
        if (hours > 0) {
          return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}, $hours hour${hours > 1 ? 's' : ''} ago';
        }
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else if (diff.inHours > 0) {
        final minutes = diff.inMinutes % 60;
        if (minutes > 0) {
          return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}, $minutes minute${minutes > 1 ? 's' : ''} ago';
        }
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTimeStr.split('T').first;
    }
  }

  String get displayActivity {
    if (lastActivity != null && lastActivity!.trim().isNotEmpty) {
      return lastActivity!.trim();
    }
    final targetDate = lastActivityAt ?? updatedAt ?? createdAt;
    return formatTimeAgo(targetDate);
  }

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
      client: json['client'] is Map 
          ? Client.fromJson(Map<String, dynamic>.from(json['client'])) 
          : (json['client_name'] != null 
              ? Client(id: 0, name: json['client_name'].toString()) 
              : (json['client'] is String ? Client(id: 0, name: json['client'].toString()) : null)),
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
      lastActivity: json['last_activity']?.toString() ?? json['last_activity_text']?.toString() ?? json['latest_activity']?.toString(),
      lastActivityAt: json['last_activity_at']?.toString() ?? json['last_active']?.toString() ?? json['updated_at']?.toString(),
      ecgManager: () {
        final val = json['ecg_manager'] ?? json['manager'] ?? json['managers'];
        if (val == null) return null;
        if (val is List) {
          final names = val.map((e) {
            if (e is Map) return e['name'] ?? e['display_name'] ?? e.toString();
            return e.toString();
          }).where((e) => e.isNotEmpty).join(', ');
          return names.isEmpty ? null : names;
        }
        final str = val.toString().trim();
        return str.isEmpty ? null : str;
      }(),
    );
  }
}
