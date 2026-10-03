class HseDocumentModel {
  final int id;
  final String category;
  final String categoryLabel;
  final String title;
  final String fileUrl;
  final String? expiryDate;
  final String notes;
  final String uploadedByName;
  final String? uploadedAt;
  final bool requiresAcknowledgment;
  final int revisionNumber;
  final bool isCurrentRevision;
  final bool isAcknowledged;
  final String? acknowledgedAt;

  HseDocumentModel({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.fileUrl,
    required this.expiryDate,
    required this.notes,
    required this.uploadedByName,
    required this.uploadedAt,
    required this.requiresAcknowledgment,
    required this.revisionNumber,
    required this.isCurrentRevision,
    required this.isAcknowledged,
    required this.acknowledgedAt,
  });

  factory HseDocumentModel.fromJson(Map<String, dynamic> json) {
    return HseDocumentModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      category: json['category']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString(),
      notes: json['notes']?.toString() ?? '',
      uploadedByName: json['uploaded_by_name']?.toString() ?? '',
      uploadedAt: json['uploaded_at']?.toString(),
      requiresAcknowledgment: json['requires_acknowledgment'] == true,
      revisionNumber: json['revision_number'] is int ? json['revision_number'] : int.tryParse('${json['revision_number']}') ?? 1,
      isCurrentRevision: json['is_current_revision'] != false,
      isAcknowledged: json['is_acknowledged'] == true,
      acknowledgedAt: json['acknowledged_at']?.toString(),
    );
  }
}
