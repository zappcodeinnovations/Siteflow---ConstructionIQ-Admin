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
  final int? signedCount;
  final int? totalSigners;
  // Only present for category == 'rams' - a structured hazard matrix exists
  // underneath this document. Null means either not a RAMS document, or an
  // older RAMS upload created before the builder existed (no risk_assessment
  // row) - the card should offer "Build RAMS" instead of "Open RAMS builder"
  // for that case, same as the web list does.
  final int? hazardCount;
  final int? highestRiskScore;

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
    this.signedCount,
    this.totalSigners,
    this.hazardCount,
    this.highestRiskScore,
  });

  factory HseDocumentModel.fromJson(Map<String, dynamic> json) {
    final signedCount = json['signed_count'] ?? json['signed_users_count'] ?? json['acknowledged_count'] ?? json['signatures_count'];
    final totalSigners = json['total_signers'] ?? json['total_workers'] ?? json['required_count'] ?? json['total_required'];
    final riskAssessment = json['risk_assessment'] is Map
        ? (json['risk_assessment'] as Map).cast<String, dynamic>()
        : null;

    return HseDocumentModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      category: json['category']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? json['filename'] ?? 'Untitled Document',
      fileUrl: json['file_url']?.toString() ?? json['file']?.toString() ?? json['url']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? json['expires_at']?.toString() ?? json['expiry']?.toString(),
      notes: json['notes']?.toString() ?? json['description']?.toString() ?? '',
      uploadedByName: json['uploaded_by_name']?.toString() ??
          json['uploaded_by']?.toString() ??
          json['uploader_name']?.toString() ??
          json['uploader_email']?.toString() ??
          '',
      uploadedAt: json['uploaded_at']?.toString() ??
          json['created_at']?.toString() ??
          json['created']?.toString() ??
          json['submission_date']?.toString() ??
          json['submitted_at']?.toString() ??
          json['date']?.toString(),
      requiresAcknowledgment: json['requires_acknowledgment'] == true || json['require_sign'] == true,
      revisionNumber: json['revision_number'] is int ? json['revision_number'] : int.tryParse('${json['revision_number']}') ?? 1,
      isCurrentRevision: json['is_current_revision'] != false,
      isAcknowledged: json['is_acknowledged'] == true,
      acknowledgedAt: json['acknowledged_at']?.toString(),
      signedCount: signedCount is int ? signedCount : int.tryParse('$signedCount'),
      totalSigners: totalSigners is int ? totalSigners : int.tryParse('$totalSigners'),
      hazardCount: riskAssessment?['hazard_count'] is int
          ? riskAssessment!['hazard_count'] as int
          : int.tryParse('${riskAssessment?['hazard_count']}'),
      highestRiskScore: riskAssessment?['highest_risk_score'] is int
          ? riskAssessment!['highest_risk_score'] as int
          : int.tryParse('${riskAssessment?['highest_risk_score']}'),
    );
  }
}
