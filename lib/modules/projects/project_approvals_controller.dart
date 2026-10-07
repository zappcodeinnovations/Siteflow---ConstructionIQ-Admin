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
}
