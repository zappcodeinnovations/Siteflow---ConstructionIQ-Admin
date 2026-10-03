import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/hse_document_model.dart';

class ProjectHseController extends ChangeNotifier {
  final int projectId;
  ProjectHseController(this.projectId);

  bool isLoading = false;
  String? error;
  List<HseDocumentModel> documents = [];

  Future<void> fetchDocuments() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectHseDocuments(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        documents = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => HseDocumentModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch HS&E documents.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
