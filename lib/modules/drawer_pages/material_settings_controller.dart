import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class MaterialSettingsController extends ChangeNotifier {
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> tags = [];

  Future<void> fetchAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([_fetchGroups(), _fetchTags()]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchGroups() async {
    try {
      final response = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/material-groups/');
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        groups = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        errorMessage = decoded['message']?.toString() ?? 'Failed to load material groups.';
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
    }
  }

  Future<void> _fetchTags() async {
    try {
      final response = await ApiClient.get('${ApiEndpoints.baseUrl}/admin/material-tags/');
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        tags = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        errorMessage = decoded['message']?.toString() ?? 'Failed to load material tags.';
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
    }
  }

  Future<Map<String, dynamic>> createGroup(String name) async {
    return _mutate('${ApiEndpoints.baseUrl}/admin/material-groups/', 'POST', {"name": name}, refetch: _fetchGroups);
  }

  Future<Map<String, dynamic>> renameGroup(int id, String name) async {
    return _mutate('${ApiEndpoints.baseUrl}/admin/material-groups/$id/', 'PATCH', {"name": name}, refetch: _fetchGroups);
  }

  Future<Map<String, dynamic>> deleteGroup(int id) async {
    return _mutate('${ApiEndpoints.baseUrl}/admin/material-groups/$id/', 'DELETE', null, refetch: _fetchGroups);
  }

  Future<Map<String, dynamic>> createTag(String name) async {
    return _mutate('${ApiEndpoints.baseUrl}/admin/material-tags/', 'POST', {"name": name}, refetch: _fetchTags);
  }

  Future<Map<String, dynamic>> renameTag(int id, String name) async {
    return _mutate('${ApiEndpoints.baseUrl}/admin/material-tags/$id/', 'PATCH', {"name": name}, refetch: _fetchTags);
  }

  Future<Map<String, dynamic>> deleteTag(int id) async {
    return _mutate('${ApiEndpoints.baseUrl}/admin/material-tags/$id/', 'DELETE', null, refetch: _fetchTags);
  }

  Future<Map<String, dynamic>> _mutate(
    String url,
    String method,
    Map<String, dynamic>? body, {
    required Future<void> Function() refetch,
  }) async {
    isSaving = true;
    notifyListeners();
    try {
      final response = method == 'POST'
          ? await ApiClient.post(url, body: body)
          : method == 'PATCH'
              ? await ApiClient.patch(url, body: body)
              : await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refetch();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Done.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Request failed.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
