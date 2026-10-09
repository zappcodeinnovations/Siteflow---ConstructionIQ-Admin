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

  int formsPage = 1;
  int formsTotalCount = 0;
  int formsPageSize = 25;
  String formsStatus = 'active';
  String formsSearch = '';

  int templatesPage = 1;
  int templatesTotalCount = 0;
  int templatesPageSize = 25;
  String templatesStatus = 'active';
  String templatesSearch = '';

  Future<void> fetchForms({String? status, String? search, int? page}) async {
    isLoadingForms = true;
    formsError = null;
    if (status != null) formsStatus = status;
    if (search != null) formsSearch = search;
    if (page != null) formsPage = page;
    notifyListeners();
    try {
      final params = <String, String>{
        if (formsStatus.isNotEmpty) 'status': formsStatus,
        if (formsSearch.trim().isNotEmpty) 'search': formsSearch.trim(),
        'page': formsPage.toString(),
      };
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryForms}?$query';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        formsTotalCount = decoded['count'] is int ? decoded['count'] : (decoded['data'] is List ? (decoded['data'] as List).length : 0);
        forms = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => LibraryFormModel.fromJson(e.cast<String, dynamic>()))
            .toList();
        if (formsTotalCount == 0 && forms.isNotEmpty) {
          formsTotalCount = forms.length;
        }
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

  Future<Map<String, dynamic>> createForm(String name) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryForms}';
      final response = await ApiClient.post(url, body: {"name": name});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || (response.statusCode == 200 && decoded['status'] == true)) {
        await fetchForms();
        return {"success": true, "message": decoded['message'] ?? 'Form created successfully.', "data": decoded['data']};
      }
      if (response.statusCode == 405) {
        return {
          "success": false,
          "message": "Form creation is not supported via mobile API (HTTP 405). Forms must be designed and configured using the Web Admin Form Builder."
        };
      }
      final errMsg = decoded['message'] ?? decoded['detail'] ?? decoded['error'] ?? 'Failed to create form.';
      return {"success": false, "message": errMsg.toString()};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteForm(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryForms}$id/';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204 || decoded['status'] == true) {
        await fetchForms();
        return {"success": true, "message": decoded['message'] ?? 'Form deleted successfully.'};
      }
      if (response.statusCode == 405) {
        return {
          "success": false,
          "message": "Form deletion is not supported via mobile API (HTTP 405). Please manage forms in the Web Admin."
        };
      }
      final errMsg = decoded['message'] ?? decoded['detail'] ?? decoded['error'] ?? 'Failed to delete form.';
      return {"success": false, "message": errMsg.toString()};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
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

  Future<void> fetchTemplates({String? status, String? search, int? page}) async {
    isLoadingTemplates = true;
    templatesError = null;
    if (status != null) templatesStatus = status;
    if (search != null) templatesSearch = search;
    if (page != null) templatesPage = page;
    notifyListeners();
    try {
      final params = <String, String>{
        if (templatesStatus.isNotEmpty) 'status': templatesStatus,
        if (templatesSearch.trim().isNotEmpty) 'search': templatesSearch.trim(),
        'page': templatesPage.toString(),
      };
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplates}?$query';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        templatesTotalCount = decoded['count'] is int ? decoded['count'] : (decoded['data'] is List ? (decoded['data'] as List).length : 0);
        templates = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => LibraryTemplateModel.fromJson(e.cast<String, dynamic>()))
            .toList();
        if (templatesTotalCount == 0 && templates.isNotEmpty) {
          templatesTotalCount = templates.length;
        }
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
