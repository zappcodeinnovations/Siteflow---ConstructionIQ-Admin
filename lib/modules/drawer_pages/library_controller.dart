import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/library_form_model.dart';
import '../../models/library_template_model.dart';
import '../../models/project_material_model.dart';

/// Backs the Library screen's three tabs (Forms/Materials/Templates) -
/// same {status, message, data} response shape as the project tabs, so
/// one controller covers all three instead of duplicating fetch plumbing.
class LibraryController extends ChangeNotifier {
  bool isLoadingForms = false;
  bool isLoadingMaterials = false;
  bool isLoadingTemplates = false;

  String? formsError;
  String? materialsError;
  String? templatesError;

  List<LibraryFormModel> forms = [];
  List<LibraryMaterialModel> materials = [];
  List<LibraryTemplateModel> templates = [];

  bool isLoadingWorkTypes = false;
  String? workTypesError;
  List<Map<String, dynamic>> workTypes = [];

  Future<void> fetchForms() async {
    isLoadingForms = true;
    formsError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.libraryForms;
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        forms = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => LibraryFormModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        formsError = decoded['message']?.toString() ?? 'Failed to fetch library forms.';
      }
    } catch (e) {
      formsError = 'An error occurred: $e';
    } finally {
      isLoadingForms = false;
      notifyListeners();
    }
  }

  Future<void> fetchMaterials() async {
    isLoadingMaterials = true;
    materialsError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.libraryMaterials;
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        materials = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => LibraryMaterialModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        materialsError = decoded['message']?.toString() ?? 'Failed to fetch materials.';
      }
    } catch (e) {
      materialsError = 'An error occurred: $e';
    } finally {
      isLoadingMaterials = false;
      notifyListeners();
    }
  }

  Future<void> fetchTemplates() async {
    isLoadingTemplates = true;
    templatesError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.libraryTemplates;
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        templates = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => LibraryTemplateModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        templatesError = decoded['message']?.toString() ?? 'Failed to fetch project templates.';
      }
    } catch (e) {
      templatesError = 'An error occurred: $e';
    } finally {
      isLoadingTemplates = false;
      notifyListeners();
    }
  }

  Future<void> fetchWorkTypes() async {
    isLoadingWorkTypes = true;
    workTypesError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminWorkTypes;
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        workTypes = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        workTypesError = decoded['message']?.toString() ?? 'Failed to fetch work types.';
      }
    } catch (e) {
      workTypesError = 'An error occurred: $e';
    } finally {
      isLoadingWorkTypes = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createWorkType(String name) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminWorkTypes;
      final response = await ApiClient.post(url, body: {"name": name});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchWorkTypes();
        return {"success": true, "message": decoded['message'] ?? 'Work type added.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to add work type.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> toggleWorkType(int id, bool isActive) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminWorkTypeDetail(id);
      final response = await ApiClient.patch(url, body: {"is_active": isActive});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchWorkTypes();
        return {"success": true, "message": decoded['message'] ?? 'Updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to update work type.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> renameWorkType(int id, String name) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminWorkTypeDetail(id);
      final response = await ApiClient.patch(url, body: {"name": name});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchWorkTypes();
        return {"success": true, "message": decoded['message'] ?? 'Updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to rename work type.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteWorkType(int id) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminWorkTypeDetail(id);
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchWorkTypes();
        return {"success": true, "message": decoded['message'] ?? 'Work type deleted.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to delete work type.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
