import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/job_create_setup_model.dart';
import '../../models/project_model.dart';

class OperativeOptionItem {
  final String id;
  final String name;
  final String? role;

  OperativeOptionItem({required this.id, required this.name, this.role});
}

class CreateTaskController extends ChangeNotifier {
  int? selectedProjectId;
  List<Project> projects = [];
  JobCreateSetupModel? setup;

  // Scoped to whichever project is currently selected (via setup.operatives)
  // - empty until a project is chosen, exactly like the web's own "Start
  // New Task Online" modal, which starts its operative <select> with no
  // options and only populates it once a project is picked. Previously
  // this pulled the entire org-wide /admin/members/?role=operative
  // directory regardless of project.
  List<OperativeOptionItem> get operatives => (setup?.operatives ?? [])
      .map((o) => OperativeOptionItem(id: o.id, name: o.name, role: null))
      .toList();

  bool isLoadingProjects = false;
  bool isLoadingSetup = false;
  bool isSubmitting = false;
  String? setupError;

  CreateTaskController({this.selectedProjectId});

  Future<void> init(int? initialProjectId) async {
    selectedProjectId = initialProjectId;
    await fetchProjects();
    // Leave the Project field empty (placeholder) when opened without a
    // project already in context, matching the web's own "Start New Task
    // Online" modal - the user must explicitly choose one, same as the
    // operatives list above staying empty until that happens. This used to
    // silently auto-select the first project in the list.
    if (selectedProjectId != null) {
      await fetchSetupForProject(selectedProjectId!);
    }
  }

  Future<void> fetchProjects() async {
    isLoadingProjects = true;
    notifyListeners();
    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projects);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        projects = list.map((json) => Project.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching projects for task creation: $e");
    } finally {
      isLoadingProjects = false;
      notifyListeners();
    }
  }

  static bool isEligibleOperativeName(String? name) {
    if (name == null) return false;
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty || lower == '-' || lower == 'null' || lower == 'none' || lower == 'n/a') {
      return false;
    }
    const excluded = {
      'all',
      'all operatives',
      'all members',
      'all users',
      'admin',
      'admins',
      'super admin',
      'superadmin',
      'super admins',
      'manager',
      'managers',
      'project manager',
      'project managers',
      'site manager',
      'site managers',
      'general manager',
      'general managers',
      'management',
      'supervisor',
      'supervisors',
      'client',
      'clients',
      'guest',
      'guests',
      'staff',
      'operative',
      'operatives',
      'select operative',
      'select an operative',
      'choose operative',
      'choose operatives',
    };
    return !excluded.contains(lower);
  }

  static bool isEligibleOperativeMember({required String role, required String roleDisplayName, required String name}) {
    if (!isEligibleOperativeName(name)) return false;

    final lowerRole = role.trim().toLowerCase();
    final lowerRoleDisplay = roleDisplayName.trim().toLowerCase();

    if (lowerRole.isNotEmpty || lowerRoleDisplay.isNotEmpty) {
      final isOperativeRole = lowerRole == 'operative' ||
          lowerRole == 'operatives' ||
          lowerRoleDisplay == 'operative' ||
          lowerRoleDisplay == 'operatives';
      if (!isOperativeRole) {
        return false;
      }
    }
    return true;
  }

  Future<void> fetchSetupForProject(int projectId) async {
    selectedProjectId = projectId;
    isLoadingSetup = true;
    setupError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectJobCreate(projectId);
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setup = JobCreateSetupModel.fromJson(decoded);
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

  Future<Map<String, dynamic>> scheduleJobs({
    required int projectId,
    required String reference,
    required List<String> operativeIds,
    required List<String> scheduledDates,
    List<String> formNames = const [],
    bool withoutSheet = false,
    String? siteContact,
    String? instructions,
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/projects/$projectId/jobs/schedule/';
      final body = <String, dynamic>{
        'reference': reference,
        'operative_ids': operativeIds,
        'scheduled_dates': scheduledDates,
        'recording_method': withoutSheet ? 'without_sheet' : 'with_sheet',
        if (!withoutSheet) 'form_names': formNames,
        if (siteContact != null && siteContact.isNotEmpty) 'site_contact': siteContact,
        if (instructions != null && instructions.isNotEmpty) 'instructions': instructions,
      };

      final response = await ApiClient.post(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        return {'success': true, 'message': decoded['message']?.toString() ?? 'Jobs scheduled successfully.'};
      }
      return {'success': false, 'message': decoded['message']?.toString() ?? 'Failed to schedule jobs.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createTask({
    required int projectId,
    required String reference,
    List<int> formIds = const [],
    String? operativeId,
    String? operativeName,
    String? siteContact,
    String? instructions,
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectJobCreate(projectId);
      final body = <String, dynamic>{
        'reference': reference,
        'recording_method': formIds.isNotEmpty ? 'with_sheet' : 'without_sheet',
        if (formIds.isNotEmpty) 'form_ids': formIds,
        if (operativeId != null && operativeId.isNotEmpty) 'assigned_to': operativeId,
        if (operativeName != null && operativeName.isNotEmpty) 'operative': operativeName,
        if (siteContact != null && siteContact.isNotEmpty) 'site_contact': siteContact,
        if (instructions != null && instructions.isNotEmpty) 'instructions': instructions,
      };

      final response = await ApiClient.post(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || (response.statusCode == 200 && decoded['status'] == true)) {
        return {'success': true, 'message': decoded['message']?.toString() ?? 'Task created successfully.'};
      }
      String message = 'Failed to create task.';
      if (decoded is Map) {
        final errorLists = decoded.values.whereType<List>().expand((v) => v).toList();
        final firstError = errorLists.isNotEmpty ? errorLists.first : null;
        message = decoded['detail']?.toString() ?? decoded['message']?.toString() ?? firstError?.toString() ?? message;
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
