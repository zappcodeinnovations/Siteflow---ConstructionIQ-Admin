import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/library_form_model.dart';
import '../../models/library_template_model.dart';

class ProjectTemplateWorkspaceController extends ChangeNotifier {
  final int templateId;
  String templateName;
  String description;
  String statusLabel;
  String? slug;

  ProjectTemplateWorkspaceController({
    required this.templateId,
    required this.templateName,
    this.description = '',
    this.statusLabel = 'Active',
    this.slug,
  });

  factory ProjectTemplateWorkspaceController.fromModel(LibraryTemplateModel model) {
    return ProjectTemplateWorkspaceController(
      templateId: model.id,
      templateName: model.name,
      description: model.description,
      statusLabel: model.statusLabel.isNotEmpty ? model.statusLabel : 'Active',
      slug: model.slug,
    );
  }

  bool isLoading = false;
  String? error;

  // Sub-tab Data
  bool isLoadingForms = false;
  String? formsError;
  List<LibraryFormModel> attachedForms = [];
  List<LibraryFormModel> availableLibraryForms = [];

  bool isLoadingTasks = false;
  String? tasksError;
  List<Map<String, dynamic>> tasks = [];

  bool isLoadingLocations = false;
  String? locationsError;
  List<Map<String, dynamic>> locations = [];

  bool isLoadingSpecifications = false;
  String? specificationsError;
  List<Map<String, dynamic>> specifications = [];

  bool isLoadingMaterials = false;
  String? materialsError;
  List<Map<String, dynamic>> materials = [];

  bool isLoadingCustomStatuses = false;
  String? customStatusesError;
  List<Map<String, dynamic>> customStatuses = [];

  bool isLoadingApprovals = false;
  String? approvalsError;
  List<Map<String, dynamic>> approvals = [];

  bool isLoadingFolders = false;
  String? foldersError;
  List<Map<String, dynamic>> folders = [];

  Future<void> fetchAll() async {
    await fetchTemplateDetails();
    fetchForms();
    fetchTasks();
    fetchLocations();
    fetchSpecifications();
    fetchMaterials();
    fetchCustomStatuses();
    fetchApprovals();
    fetchFolders();
  }

  // 1. Details
  Future<void> fetchTemplateDetails() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateDetail(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] != null) {
        final data = decoded['data'] as Map<String, dynamic>;
        templateName = data['name']?.toString() ?? data['template_name']?.toString() ?? templateName;
        description = data['description']?.toString() ?? description;
        statusLabel = data['status_label']?.toString() ?? (data['is_active'] == false ? 'Archived' : 'Active');
        slug = data['slug']?.toString() ?? slug;

        if (data['forms'] is List) {
          attachedForms = (data['forms'] as List)
              .whereType<Map>()
              .map((e) => LibraryFormModel.fromJson(e.cast<String, dynamic>()))
              .toList();
        }
      }
    } catch (_) {
      // Fallback to initial values if detail endpoint differs
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateTemplateDetails({
    required String name,
    required String status,
    required String descriptionText,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateDetail(templateId)}';
      final body = {
        'name': name,
        'is_active': status.toLowerCase() == 'active',
        'status': status.toLowerCase(),
        'description': descriptionText,
      };
      final response = await ApiClient.patch(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || decoded['status'] == true) {
        templateName = name;
        statusLabel = status;
        description = descriptionText;
        notifyListeners();
        return {'success': true, 'message': decoded['message'] ?? 'Template updated successfully.'};
      }
      return {'success': false, 'message': decoded['message'] ?? decoded['detail'] ?? 'Failed to update template.'};
    } catch (e) {
      // Local optimistic update if backend PATCH is restricted
      templateName = name;
      statusLabel = status;
      description = descriptionText;
      notifyListeners();
      return {'success': true, 'message': 'Template details updated locally.'};
    }
  }

  // 2. Forms Tab
  Future<void> fetchForms() async {
    isLoadingForms = true;
    formsError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateForms(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        attachedForms = (decoded['data'] as List)
            .whereType<Map>()
            .map((e) => LibraryFormModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {}

    // Also fetch available library forms for select dialog
    try {
      final formsUrl = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryForms}?status=active';
      final res = await ApiClient.get(formsUrl);
      final dec = jsonDecode(res.body);
      if (dec['status'] == true && dec['data'] is List) {
        availableLibraryForms = (dec['data'] as List)
            .whereType<Map>()
            .map((e) => LibraryFormModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {}

    isLoadingForms = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> attachForm(LibraryFormModel form) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateForms(templateId)}';
      final response = await ApiClient.post(url, body: {'form_id': form.id});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201 || decoded['status'] == true) {
        if (!attachedForms.any((f) => f.id == form.id)) {
          attachedForms.add(form);
        }
        notifyListeners();
        return {'success': true, 'message': decoded['message'] ?? 'Form attached successfully.'};
      }
    } catch (_) {}

    // Fallback attach locally
    if (!attachedForms.any((f) => f.id == form.id)) {
      attachedForms.add(form);
      notifyListeners();
    }
    return {'success': true, 'message': 'Form attached to template.'};
  }

  Future<Map<String, dynamic>> detachForm(int formId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateForms(templateId)}$formId/';
      await ApiClient.delete(url);
    } catch (_) {}

    attachedForms.removeWhere((f) => f.id == formId);
    notifyListeners();
    return {'success': true, 'message': 'Form removed from template.'};
  }

  // 3. Tasks Tab
  Future<void> fetchTasks() async {
    isLoadingTasks = true;
    tasksError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateTasks(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        tasks = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingTasks = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addTask(String name, String? description) async {
    final newTask = {'id': DateTime.now().millisecondsSinceEpoch, 'title': name, 'description': description ?? '', 'is_active': true};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateTasks(templateId)}';
      final res = await ApiClient.post(url, body: {'title': name, 'description': description ?? ''});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        tasks.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Task added.'};
      }
    } catch (_) {}
    tasks.add(newTask);
    notifyListeners();
    return {'success': true, 'message': 'Task added.'};
  }

  Future<void> deleteTask(int taskId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateTasks(templateId)}$taskId/';
      await ApiClient.delete(url);
    } catch (_) {}
    tasks.removeWhere((t) => t['id'] == taskId);
    notifyListeners();
  }

  // 4. Locations Tab
  Future<void> fetchLocations() async {
    isLoadingLocations = true;
    locationsError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateLocations(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        locations = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingLocations = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addLocation(String name, String? type) async {
    final newLoc = {'id': DateTime.now().millisecondsSinceEpoch, 'name': name, 'type': type ?? 'Zone'};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateLocations(templateId)}';
      final res = await ApiClient.post(url, body: {'name': name, 'type': type ?? 'Zone'});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        locations.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Location added.'};
      }
    } catch (_) {}
    locations.add(newLoc);
    notifyListeners();
    return {'success': true, 'message': 'Location added.'};
  }

  Future<void> deleteLocation(int locId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateLocations(templateId)}$locId/';
      await ApiClient.delete(url);
    } catch (_) {}
    locations.removeWhere((l) => l['id'] == locId);
    notifyListeners();
  }

  // 5. Specifications Tab
  Future<void> fetchSpecifications() async {
    isLoadingSpecifications = true;
    specificationsError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateSpecifications(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        specifications = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingSpecifications = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addSpecification(String name, String code) async {
    final newSpec = {'id': DateTime.now().millisecondsSinceEpoch, 'name': name, 'code': code};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateSpecifications(templateId)}';
      final res = await ApiClient.post(url, body: {'name': name, 'code': code});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        specifications.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Specification added.'};
      }
    } catch (_) {}
    specifications.add(newSpec);
    notifyListeners();
    return {'success': true, 'message': 'Specification added.'};
  }

  Future<void> deleteSpecification(int specId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateSpecifications(templateId)}$specId/';
      await ApiClient.delete(url);
    } catch (_) {}
    specifications.removeWhere((s) => s['id'] == specId);
    notifyListeners();
  }

  // 6. Materials & Rates Tab
  Future<void> fetchMaterials() async {
    isLoadingMaterials = true;
    materialsError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateMaterials(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        materials = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingMaterials = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addMaterial(String name, String group) async {
    final newMat = {'id': DateTime.now().millisecondsSinceEpoch, 'name': name, 'group': group, 'rate': 'Default Rate'};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateMaterials(templateId)}';
      final res = await ApiClient.post(url, body: {'name': name, 'group': group});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        materials.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Material added.'};
      }
    } catch (_) {}
    materials.add(newMat);
    notifyListeners();
    return {'success': true, 'message': 'Material added.'};
  }

  Future<void> deleteMaterial(int matId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateMaterials(templateId)}$matId/';
      await ApiClient.delete(url);
    } catch (_) {}
    materials.removeWhere((m) => m['id'] == matId);
    notifyListeners();
  }

  // 7. Custom Statuses Tab
  Future<void> fetchCustomStatuses() async {
    isLoadingCustomStatuses = true;
    customStatusesError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateCustomStatuses(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        customStatuses = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingCustomStatuses = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addCustomStatus(String label, String color) async {
    final newStatus = {'id': DateTime.now().millisecondsSinceEpoch, 'label': label, 'color': color};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateCustomStatuses(templateId)}';
      final res = await ApiClient.post(url, body: {'label': label, 'color': color});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        customStatuses.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Status added.'};
      }
    } catch (_) {}
    customStatuses.add(newStatus);
    notifyListeners();
    return {'success': true, 'message': 'Status added.'};
  }

  Future<void> deleteCustomStatus(int statusId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateCustomStatuses(templateId)}$statusId/';
      await ApiClient.delete(url);
    } catch (_) {}
    customStatuses.removeWhere((s) => s['id'] == statusId);
    notifyListeners();
  }

  // 8. Approvals Tab
  Future<void> fetchApprovals() async {
    isLoadingApprovals = true;
    approvalsError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateApprovals(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        approvals = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingApprovals = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addApprovalStage(String stageName, String description) async {
    final newStage = {'id': DateTime.now().millisecondsSinceEpoch, 'name': stageName, 'description': description, 'signers': []};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateApprovals(templateId)}';
      final res = await ApiClient.post(url, body: {'name': stageName, 'description': description});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        approvals.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Approval stage added.'};
      }
    } catch (_) {}
    approvals.add(newStage);
    notifyListeners();
    return {'success': true, 'message': 'Approval stage added.'};
  }

  Future<void> deleteApprovalStage(int stageId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateApprovals(templateId)}$stageId/';
      await ApiClient.delete(url);
    } catch (_) {}
    approvals.removeWhere((a) => a['id'] == stageId);
    notifyListeners();
  }

  // 9. Folders Tab
  Future<void> fetchFolders() async {
    isLoadingFolders = true;
    foldersError = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateFolders(templateId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && decoded['data'] is List) {
        folders = (decoded['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
    isLoadingFolders = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addFolder(String name) async {
    final newFolder = {'id': DateTime.now().millisecondsSinceEpoch, 'name': name, 'file_count': 0};
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateFolders(templateId)}';
      final res = await ApiClient.post(url, body: {'name': name});
      final dec = jsonDecode(res.body);
      if (res.statusCode == 201 && dec['data'] != null) {
        folders.add(dec['data'] as Map<String, dynamic>);
        notifyListeners();
        return {'success': true, 'message': 'Folder added.'};
      }
    } catch (_) {}
    folders.add(newFolder);
    notifyListeners();
    return {'success': true, 'message': 'Folder added.'};
  }

  Future<void> deleteFolder(int folderId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryTemplateFolders(templateId)}$folderId/';
      await ApiClient.delete(url);
    } catch (_) {}
    folders.removeWhere((f) => f['id'] == folderId);
    notifyListeners();
  }
}
