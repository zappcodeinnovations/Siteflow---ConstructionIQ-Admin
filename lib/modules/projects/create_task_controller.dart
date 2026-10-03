import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/job_create_setup_model.dart';

class CreateTaskController extends ChangeNotifier {
  final int projectId;
  CreateTaskController(this.projectId);

  bool isLoadingSetup = false;
  bool isSubmitting = false;
  String? setupError;
  JobCreateSetupModel? setup;

  Future<void> fetchSetup() async {
    isLoadingSetup = true;
    setupError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectJobCreate(projectId);
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        setup = JobCreateSetupModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final decoded = jsonDecode(response.body);
        setupError = decoded['detail']?.toString() ?? 'Failed to load task setup.';
      }
    } catch (e) {
      setupError = 'An error occurred: $e';
    } finally {
      isLoadingSetup = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createTask({
    required String reference,
    required String recordingMethod,
    List<int> formIds = const [],
    String siteContact = '',
    String instructions = '',
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectJobCreate(projectId);
      final response = await ApiClient.post(url, body: {
        'reference': reference,
        'recording_method': recordingMethod,
        if (formIds.isNotEmpty) 'form_ids': formIds,
        if (siteContact.isNotEmpty) 'site_contact': siteContact,
        if (instructions.isNotEmpty) 'instructions': instructions,
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': decoded['message']?.toString() ?? 'Task created.'};
      }
      String message = 'Failed to create task.';
      if (decoded is Map) {
        final errorLists = decoded.values.whereType<List>().expand((v) => v).toList();
        final firstError = errorLists.isNotEmpty ? errorLists.first : null;
        message = decoded['detail']?.toString() ?? firstError?.toString() ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
