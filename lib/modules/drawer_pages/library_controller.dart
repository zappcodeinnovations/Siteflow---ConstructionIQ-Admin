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
}
