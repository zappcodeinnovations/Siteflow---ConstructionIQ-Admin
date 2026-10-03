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
}
