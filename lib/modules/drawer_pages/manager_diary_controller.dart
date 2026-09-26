import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/manager_diary_model.dart';

class ManagerDiaryController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ManagerDiaryEntry> _entries = [];
  List<ManagerDiaryEntry> get entries => _entries;

  Future<void> fetchEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.managerDiary);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        final list = decoded['data'] as List<dynamic>? ?? [];
        _entries = list.map((e) => ManagerDiaryEntry.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = decoded['message'] ?? 'Failed to fetch Manager Diary';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ManagerDiaryFormsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ManagerDiaryForm> _forms = [];
  List<ManagerDiaryForm> get forms => _forms;

  Future<void> fetchForms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.managerDiaryForms);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        final list = decoded['data'] as List<dynamic>? ?? [];
        _forms = list.map((e) => ManagerDiaryForm.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = decoded['message'] ?? 'Failed to fetch forms';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
