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
    required this.notes,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist_items'];
    return InspectionModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      referenceNo: json['reference_no']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      checklistItems: rawChecklist is List
          ? rawChecklist
              .whereType<Map>()
              .map((e) => InspectionChecklistItem.fromJson(e.cast<String, dynamic>()))
              .toList()
          : [],
      inspectorName: json['inspector_name']?.toString() ?? '',
      drawingLocationReference: json['drawing_location_reference']?.toString() ?? '',
      scheduledDate: DateTime.tryParse(json['scheduled_date']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      notes: json['notes']?.toString() ?? '',
    );
  }
}
