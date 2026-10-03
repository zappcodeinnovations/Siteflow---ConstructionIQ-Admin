import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/project_template_detail_model.dart';

class ProjectTemplateController extends ChangeNotifier {
  final int projectId;
  ProjectTemplateController(this.projectId);

  bool isLoading = false;
  String? error;
  ProjectTemplateDetailModel? template;
  bool hasNoTemplate = false;

  Future<void> fetchTemplate() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectTemplateDetail(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        if (decoded['data'] == null) {
          hasNoTemplate = true;
          template = null;
        } else {
          hasNoTemplate = false;
          template = ProjectTemplateDetailModel.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch project template.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
