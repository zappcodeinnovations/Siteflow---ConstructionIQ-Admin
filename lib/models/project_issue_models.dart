import '../core/utils/date_helper.dart';

class IncidentModel {
  final int id;
  final String referenceNo;
  final bool isNearMiss;
  final String typeLabel;
  final String severity;
  final String severityLabel;
  final String title;
  final String description;
  final DateTime? occurredAt;
  final String locationText;
  final String status;
  final String statusLabel;
  final String reportedByName;
  final List<String> photoUrls;

  IncidentModel({
    required this.id,
    required this.referenceNo,
    required this.isNearMiss,
    required this.typeLabel,
    required this.severity,
    required this.severityLabel,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.locationText,
    required this.status,
    required this.statusLabel,
    required this.reportedByName,
    required this.photoUrls,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      referenceNo: json['reference_no']?.toString() ?? '',
      isNearMiss: json['is_near_miss'] == true,
      typeLabel: json['type_label']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'low',
      severityLabel: json['severity_label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
      locationText: json['location_text']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      reportedByName: json['reported_by_name']?.toString() ?? '',
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class SnagModel {
  final int id;
  final String referenceNo;
  final String category;
  final String categoryLabel;
  final String? categorySpecify;
  final String? linkedPin;
  final String severity;
  final String severityLabel;
  final String title;
  final String description;
  final DateTime? dueDate;
  final int? assignedToId;
  final String assignedToName;
  final String status;
  final String statusLabel;
  final String reportedByName;
  final List<String> photoUrls;

  SnagModel({
    required this.id,
    required this.referenceNo,
    required this.category,
    required this.categoryLabel,
    this.categorySpecify,
    this.linkedPin,
    required this.severity,
    required this.severityLabel,
    required this.title,
    required this.description,
    required this.dueDate,
    this.assignedToId,
    required this.assignedToName,
    required this.status,
    required this.statusLabel,
    required this.reportedByName,
    required this.photoUrls,
  });

  factory SnagModel.fromJson(Map<String, dynamic> json) {
    return SnagModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      referenceNo: json['reference_no']?.toString() ?? json['reference']?.toString() ?? json['code']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      categoryLabel: json['category_label']?.toString() ?? json['category']?.toString() ?? 'Other',
      categorySpecify: json['category_specify']?.toString() ?? json['specify_category']?.toString(),
      linkedPin: json['linked_pin']?.toString() ?? json['drawing_pin']?.toString() ?? json['pin_reference']?.toString(),
      severity: json['severity']?.toString() ?? 'low',
      severityLabel: json['severity_label']?.toString() ?? json['severity']?.toString() ?? 'Low',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueDate: DateTime.tryParse(json['due_date']?.toString() ?? ''),
      assignedToId: json['assigned_to_id'] is int ? json['assigned_to_id'] : int.tryParse('${json['assigned_to_id'] ?? (json['assigned_to'] is Map ? json['assigned_to']['id'] : null)}'),
      assignedToName: json['assigned_to_name']?.toString() ??
          (json['assigned_to'] is Map
              ? (json['assigned_to']['name'] ?? json['assigned_to']['display_name'] ?? json['assigned_to']['email'])
              : (json['assigned_to'] is String ? json['assigned_to'] : '')) ??
          '',
      status: json['status']?.toString() ?? 'open',
      statusLabel: json['status_label']?.toString() ?? json['status']?.toString() ?? 'Open',
      reportedByName: json['reported_by_name']?.toString() ?? '',
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ??
          ((json['photos'] as List?)?.map((e) => e.toString()).toList() ?? []),
    );
  }
}

class InspectionChecklistItem {
  final String label;
  final bool? passed;

  InspectionChecklistItem({required this.label, required this.passed});

  factory InspectionChecklistItem.fromJson(Map<String, dynamic> json) {
    return InspectionChecklistItem(
      label: json['label']?.toString() ?? '',
      passed: json['passed'] as bool?,
    );
  }
}

class InspectionModel {
  final int id;
  final String referenceNo;
  final String title;
  final String status;
  final String statusLabel;
  final List<InspectionChecklistItem> checklistItems;
  final String inspectorName;
  final String drawingLocationReference;
  final DateTime? scheduledDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final String? rawScheduledDate;
  final String? rawCompletedAt;
  final String? rawCreatedAt;
  final String notes;

  InspectionModel({
    required this.id,
    required this.referenceNo,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.checklistItems,
    required this.inspectorName,
    required this.drawingLocationReference,
    required this.scheduledDate,
    required this.completedAt,
    this.createdAt,
    this.rawScheduledDate,
    this.rawCompletedAt,
    this.rawCreatedAt,
    required this.notes,
  });

  String get formattedTimeText {
    if (rawCompletedAt != null && rawCompletedAt!.isNotEmpty && rawCompletedAt != 'null') {
      final formatted = DateHelper.formatToLocal(rawCompletedAt);
      return 'Completed $formatted';
    } else if (completedAt != null) {
      final formatted = DateHelper.formatToLocal(completedAt!.toIso8601String());
      return 'Completed $formatted';
    }

    if (rawScheduledDate != null && rawScheduledDate!.isNotEmpty && rawScheduledDate != 'null') {
      final formatted = DateHelper.formatToLocal(rawScheduledDate);
      return 'Scheduled: $formatted';
    } else if (scheduledDate != null) {
      final formatted = DateHelper.formatToLocal(scheduledDate!.toIso8601String());
      return 'Scheduled: $formatted';
    }

    if (rawCreatedAt != null && rawCreatedAt!.isNotEmpty && rawCreatedAt != 'null') {
      final formatted = DateHelper.formatToLocal(rawCreatedAt);
      return 'Logged $formatted';
    } else if (createdAt != null) {
      final formatted = DateHelper.formatToLocal(createdAt!.toIso8601String());
      return 'Logged $formatted';
    }

    return '';
  }

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist_items'] ?? json['items'];

    String inspector = json['inspector_name']?.toString() ?? '';
    if (inspector.isEmpty && json['inspector'] != null) {
      if (json['inspector'] is Map) {
        inspector = json['inspector']['name'] ?? json['inspector']['display_name'] ?? json['inspector']['username'] ?? '';
      } else {
        inspector = json['inspector'].toString();
      }
    }
    if (inspector.isEmpty && json['created_by_name'] != null) {
      inspector = json['created_by_name'].toString();
    }

    String pinRef = json['drawing_location_reference']?.toString() ??
        json['linked_pin']?.toString() ??
        json['drawing_pin']?.toString() ??
        json['pin']?.toString() ??
        '';

    final rawScheduled = json['scheduled_date']?.toString() ?? json['scheduled_at']?.toString() ?? json['inspection_date']?.toString();
    final rawCompleted = json['completed_at']?.toString() ?? json['completed_date']?.toString();
    final rawCreated = json['created_at']?.toString() ?? json['created_date']?.toString();

    return InspectionModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      referenceNo: json['reference_no']?.toString() ?? json['reference']?.toString() ?? json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? json['status']?.toString() ?? 'Pending',
      checklistItems: rawChecklist is List
          ? rawChecklist
              .whereType<Map>()
              .map((e) => InspectionChecklistItem.fromJson(e.cast<String, dynamic>()))
              .toList()
          : [],
      inspectorName: inspector,
      drawingLocationReference: pinRef,
      scheduledDate: rawScheduled != null ? DateTime.tryParse(rawScheduled) : null,
      completedAt: rawCompleted != null ? DateTime.tryParse(rawCompleted) : null,
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) : null,
      rawScheduledDate: rawScheduled,
      rawCompletedAt: rawCompleted,
      rawCreatedAt: rawCreated,
      notes: json['notes']?.toString() ?? '',
    );
  }
}
