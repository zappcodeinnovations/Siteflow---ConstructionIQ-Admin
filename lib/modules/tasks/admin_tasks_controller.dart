import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/admin_task_model.dart';

class AdminTasksController extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<AdminTaskModel> tasks = [];

  Future<void> fetchTasks() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminTasks;
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        tasks = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => AdminTaskModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch tasks.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.adminTaskDelete(taskId);
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
        return {'success': true, 'message': decoded['message'] ?? 'Task deleted.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to delete task.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
