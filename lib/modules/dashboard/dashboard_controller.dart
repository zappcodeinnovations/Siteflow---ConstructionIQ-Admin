import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/dashboard_model.dart';

class DashboardController extends ChangeNotifier {
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static void triggerGlobalRefresh() {
    refreshNotifier.value++;
  }

  // Data loaded while the splash screen is showing, handed to the first
  // dashboard so it renders immediately instead of showing a spinner.
  static DashboardData? _prefetched;
  static int _prefetchGeneration = 0;

  /// Loads the dashboard during the splash screen. A result that arrives
  /// after the dashboard has already been opened is discarded.
  static Future<void> prefetch() async {
    final generation = ++_prefetchGeneration;
    try {
      final response = await ApiClient.get(
        ApiEndpoints.baseUrl + ApiEndpoints.dashboard,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data['status'] == true &&
          generation == _prefetchGeneration) {
        _prefetched = DashboardData.fromJson(data['data']);
      }
    } catch (_) {
      // The dashboard falls back to loading on its own.
    }
  }

  static DashboardData? _takePrefetched() {
    final data = _prefetched;
    _prefetched = null;
    _prefetchGeneration++; // drop any prefetch still in flight
    return data;
  }

  DashboardController() {
    _dashboardData = _takePrefetched();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DashboardData? _dashboardData;
  DashboardData? get dashboardData => _dashboardData;

  Future<void> fetchDashboard({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await ApiClient.get(
        ApiEndpoints.baseUrl + ApiEndpoints.dashboard,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _dashboardData = DashboardData.fromJson(data['data']);
        _errorMessage = null;
      } else if (!silent) {
        _errorMessage =
            data['message'] ??
            'Failed to fetch dashboard (Status: ${response.statusCode})\nBody: ${response.body}';
      }
    } catch (e) {
      if (!silent) {
        _errorMessage = 'An error occurred while parsing dashboard: $e';
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }
}
