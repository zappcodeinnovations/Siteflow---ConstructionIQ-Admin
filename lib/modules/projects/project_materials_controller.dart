import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/project_material_model.dart';

class ProjectMaterialsController extends ChangeNotifier {
  final int projectId;
  ProjectMaterialsController(this.projectId);

  bool isLoading = false;
  String? error;
  List<ProjectMaterialModel> materials = [];

  Future<void> fetchMaterials() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectMaterials(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        materials = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ProjectMaterialModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch materials.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
