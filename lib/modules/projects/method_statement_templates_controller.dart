import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Mobile counterpart of the web's Method Statement Templates page
/// (/method-statement-templates/) - same model/fields, reached from the
/// RAMS Builder's "Manage Templates" link so a template can be created
/// without leaving the app.
class MethodStatementTemplatesController extends ChangeNotifier {
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  List<Map<String, dynamic>> active = [];
  List<Map<String, dynamic>> archived = [];

  String _url({int? templateId}) => ApiEndpoints.baseUrl +
      (templateId == null
          ? ApiEndpoints.methodStatementTemplates
          : ApiEndpoints.methodStatementTemplateDetail(templateId));

  Future<void> fetchTemplates() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await ApiClient.get(_url());
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final data = decoded['data'] as Map<String, dynamic>;
        active = ((data['active'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        archived = ((data['archived'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch templates.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createTemplate({
    required String title,
    String tradeCategory = '',
    String ppeRequired = '',
    String sequenceOfWork = '',
  }) async {
    isSaving = true;
    notifyListeners();
    try {
      final response = await ApiClient.post(_url(), body: {
        'title': title,
        'trade_category': tradeCategory,
        'ppe_required': ppeRequired,
        'sequence_of_work': sequenceOfWork,
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 && decoded['status'] == true) {
        await fetchTemplates();
        return null;
      }
      return decoded['message']?.toString() ?? 'Failed to create template.';
    } catch (e) {
      return 'An error occurred: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> updateTemplate({
    required int id,
    required String title,
    String tradeCategory = '',
    String ppeRequired = '',
    String sequenceOfWork = '',
  }) async {
    isSaving = true;
    notifyListeners();
    try {
      final response = await ApiClient.patch(_url(templateId: id), body: {
        'title': title,
        'trade_category': tradeCategory,
        'ppe_required': ppeRequired,
        'sequence_of_work': sequenceOfWork,
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        await fetchTemplates();
        return null;
      }
      return decoded['message']?.toString() ?? 'Failed to update template.';
    } catch (e) {
      return 'An error occurred: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> setActive(int id, bool isActive) async {
    isSaving = true;
    notifyListeners();
    try {
      final response = await ApiClient.patch(
        _url(templateId: id),
        body: {'is_active': isActive},
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        await fetchTemplates();
        return null;
      }
      return decoded['message']?.toString() ?? 'Failed to update template.';
    } catch (e) {
      return 'An error occurred: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
