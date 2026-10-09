import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/approval_request_model.dart';

class ProjectApprovalsController extends ChangeNotifier {
  final int projectId;
  ProjectApprovalsController(this.projectId);

  bool isLoading = false;
  String? error;
  List<ApprovalRequestModel> approvals = [];

  Future<void> fetchApprovals() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.myApprovals(projectId: projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        approvals = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ApprovalRequestModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch approvals.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isLoadingStages = false;
  String? stagesError;
  List<Map<String, dynamic>> stages = [];
  List<Map<String, dynamic>> assignableUsers = [];

  Future<void> fetchStages() async {
    isLoadingStages = true;
    stagesError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectApprovalStages(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final data = (decoded['data'] as Map).cast<String, dynamic>();
        stages = (data['stages'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        assignableUsers = (data['assignable_users'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        stagesError = decoded['message']?.toString() ?? 'Failed to fetch approval stages.';
      }
    } catch (e) {
      stagesError = 'An error occurred: $e';
    } finally {
      isLoadingStages = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> saveStage({
    int? stageId,
    required String title,
    required String declaration,
    required List<int> userIds,
  }) async {
    try {
      final url = ApiEndpoints.baseUrl +
          (stageId == null
              ? ApiEndpoints.projectApprovalStages(projectId)
              : ApiEndpoints.projectApprovalStageDetail(projectId, stageId));
      final body = {"title": title, "declaration": declaration, "user_ids": userIds};
      final response = stageId == null ? await ApiClient.post(url, body: body) : await ApiClient.patch(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchStages();
        return {"success": true, "message": decoded['message'] ?? 'Approval stage saved successfully.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to save approval stage.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteStage(int stageId) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectApprovalStageDetail(projectId, stageId);
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchStages();
        return {"success": true, "message": decoded['message'] ?? 'Approval stage deleted successfully.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to delete approval stage.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> reorderStage(int stageId, String direction) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectApprovalStageReorder(projectId);
      final response = await ApiClient.post(url, body: {"stage_id": stageId, "direction": direction});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchStages();
        return {"success": true, "message": decoded['message'] ?? 'Order updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to reorder.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
  bool isLoadingForms = false;
  String? formsError;
  List<Map<String, dynamic>> projectForms = [];

  static const List<String> defaultProjectForms = [
    'Daily Diary',
    'Daywork',
    'Diamond Drilling',
    'Passive Fire Intermittent Spraying',
    'Passive Fire Protection',
  ];

  Future<void> fetchFormApprovals() async {
    isLoadingForms = true;
    formsError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectFormApprovals(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List || decoded.containsKey('data'))) {
        final list = (decoded['data'] ?? decoded['forms'] ?? (decoded is List ? decoded : [])) as List? ?? [];
        if (list.isNotEmpty) {
          projectForms = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        } else {
          _initializeDefaultForms();
        }
      } else {
        _initializeDefaultForms();
      }
    } catch (e) {
      _initializeDefaultForms();
    } finally {
      isLoadingForms = false;
      notifyListeners();
    }
  }

  void _initializeDefaultForms() {
    if (projectForms.isEmpty) {
      projectForms = defaultProjectForms
          .map((name) => {
                'id': name.hashCode,
                'name': name,
                'is_enabled': false,
              })
          .toList();
    }
  }

  Future<bool> toggleFormApproval(dynamic formIdOrName, bool enabled) async {
    // Optimistic local update
    for (var f in projectForms) {
      if (f['id'] == formIdOrName || f['name'] == formIdOrName || f['form_id'] == formIdOrName) {
        f['is_enabled'] = enabled;
      }
    }
    notifyListeners();

    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectFormApprovals(projectId);
      final response = await ApiClient.post(url, body: {
        "form_id": formIdOrName,
        "is_enabled": enabled,
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  Future<bool> toggleAllFormApprovals(bool enabled) async {
    for (var f in projectForms) {
      f['is_enabled'] = enabled;
    }
    notifyListeners();

    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectFormApprovals(projectId);
      final response = await ApiClient.post(url, body: {
        "enable_all": enabled,
        "is_enabled": enabled,
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  Future<void> fetchAllData() async {
    await Future.wait([
      fetchApprovals(),
      fetchStages(),
      fetchFormApprovals(),
    ]);
  }
}
