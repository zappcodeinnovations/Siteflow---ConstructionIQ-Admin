import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/dashboard_model.dart';

class DashboardController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DashboardData? _dashboardData;
  DashboardData? get dashboardData => _dashboardData;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.dashboard);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _dashboardData = DashboardData.fromJson(data['data']);
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch dashboard (Status: ${response.statusCode})\nBody: ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while parsing dashboard: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}