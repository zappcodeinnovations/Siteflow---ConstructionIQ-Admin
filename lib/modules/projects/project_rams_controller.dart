import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Mobile counterpart of the web RAMS builder - fetches/saves a
/// ProjectHSEDocument(category=rams) + its structured hazard matrix via
/// ProjectRamsBuilderAPIView. Mirrors ProjectHseController's conventions
/// (same ApiClient, same isLoading/error fields) since it sits alongside it
/// in the project's HS&E tab.
class ProjectRamsController extends ChangeNotifier {
  final int projectId;
  ProjectRamsController(this.projectId);

  bool isLoading = false;
  bool isSaving = false;
  String? error;

  int? documentId;
  String title = '';
  String? expiryDate;
  bool requiresAcknowledgment = true;
  int revisionNumber = 1;

  String activityDescription = '';
  String? assessmentDate;
  String? reviewDate;
  int? methodStatementTemplateId;
  String methodStatementText = '';

  List<Map<String, dynamic>> hazards = [];
  List<Map<String, dynamic>> methodStatementTemplates = [];

  static Map<String, dynamic> emptyHazardRow() => {
        'hazard': '',
        'who_might_be_harmed': '',
        'likelihood': 1,
        'severity': 1,
        'existing_controls': '',
        'residual_likelihood': 1,
        'residual_severity': 1,
        'further_actions': '',
      };

  String _url({int? documentId}) =>
      ApiEndpoints.baseUrl + ApiEndpoints.projectRams(projectId, documentId: documentId);

  /// Loads an existing RAMS document for editing, or just the method
  /// statement template list for a brand new one (documentId == null).
  Future<void> fetchBuilderData({int? documentId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await ApiClient.get(_url(documentId: documentId));
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        final doc = (data['document'] as Map?)?.cast<String, dynamic>() ?? {};
        final ra = (data['risk_assessment'] as Map?)?.cast<String, dynamic>() ?? {};

        this.documentId = doc['id'] as int?;
        title = (doc['title'] ?? '').toString();
        expiryDate = doc['expiry_date']?.toString();
        requiresAcknowledgment = doc['requires_acknowledgment'] ?? true;
        revisionNumber = doc['revision_number'] ?? 1;

        activityDescription = (ra['activity_description'] ?? '').toString();
        assessmentDate = ra['assessment_date']?.toString();
        reviewDate = ra['review_date']?.toString();
        methodStatementTemplateId = ra['method_statement_template_id'] as int?;
        methodStatementText = (ra['method_statement_text'] ?? '').toString();

        hazards = ((data['hazards'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        methodStatementTemplates = ((data['method_statement_templates'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch RAMS data.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Saves the current state as a new RAMS document, or a new revision of
  /// `documentId` if one was passed to fetchBuilderData. Returns the error
  /// message on failure, or null on success (document_id is updated to the
  /// newly created/revised document, same as the web builder's redirect).
  Future<String?> save() async {
    isSaving = true;
    notifyListeners();
    try {
      final payload = {
        'document': {
          'title': title,
          if (expiryDate != null && expiryDate!.isNotEmpty) 'expiry_date': expiryDate,
          'requires_acknowledgment': requiresAcknowledgment,
        },
        'risk_assessment': {
          'activity_description': activityDescription,
          if (assessmentDate != null && assessmentDate!.isNotEmpty) 'assessment_date': assessmentDate,
          if (reviewDate != null && reviewDate!.isNotEmpty) 'review_date': reviewDate,
          if (methodStatementTemplateId != null) 'method_statement_template_id': methodStatementTemplateId,
          'method_statement_text': methodStatementText,
        },
        'hazards': hazards,
      };

      final response = await ApiClient.post(
        _url(documentId: documentId),
        body: payload,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        documentId = decoded['data']['document_id'] as int?;
        return null;
      }
      return decoded['message']?.toString() ?? 'Failed to save RAMS document.';
    } catch (e) {
      return 'An error occurred: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
