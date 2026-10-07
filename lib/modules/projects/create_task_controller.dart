import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/admin_member_model.dart';
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
  List<OperativeOptionItem> operatives = [];
  JobCreateSetupModel? setup;

  bool isLoadingProjects = false;
  bool isLoadingSetup = false;
  bool isLoadingOperatives = false;
  bool isSubmitting = false;
  String? setupError;

  CreateTaskController({this.selectedProjectId});

  Future<void> init(int? initialProjectId) async {
    selectedProjectId = initialProjectId;
    await Future.wait([
      fetchProjects(),
      fetchOperatives(),
    ]);
    if (selectedProjectId != null) {
      await fetchSetupForProject(selectedProjectId!);
    } else if (projects.isNotEmpty) {
      selectedProjectId = projects.first.id;
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

  Future<void> fetchOperatives() async {
    isLoadingOperatives = true;
    notifyListeners();
    try {
      final Map<String, OperativeOptionItem> map = {};

      // 1. Fetch from /admin/members/?page_size=1000
      try {
        final res = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/members/?page_size=1000');
        final data = jsonDecode(res.body);
        if (res.statusCode == 200 && (data['status'] == true || data is List || data.containsKey('data'))) {
          final parsed = AdminMemberResponse.fromJson(data);
          for (final m in parsed.data) {
            final name = m.displayName.isNotEmpty
                ? m.displayName
                : '${m.firstName} ${m.lastName}'.trim();
            if (name.isNotEmpty) {
              map[m.id.toString()] = OperativeOptionItem(
                id: m.id.toString(),
                name: name,
                role: m.roleDisplayName.isNotEmpty ? m.roleDisplayName : m.role,
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching members: $e");
      }

      // 2. Fetch from /job-sheets/filter-options/
      try {
        final res = await ApiClient.get('${ApiEndpoints.baseUrl}/job-sheets/filter-options/');
        final data = jsonDecode(res.body);
        if (res.statusCode == 200 && data['data'] != null) {
          final ops = data['data']['operatives'] as List?;
          if (ops != null) {
            for (final op in ops) {
              final name = op.toString().trim();
              if (name.isNotEmpty && !map.values.any((item) => item.name.toLowerCase() == name.toLowerCase())) {
                map[name] = OperativeOptionItem(id: name, name: name);
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching job-sheet operatives: $e");
      }

      operatives = map.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      debugPrint("Error loading operatives: $e");
    } finally {
      isLoadingOperatives = false;
      notifyListeners();
    }
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
