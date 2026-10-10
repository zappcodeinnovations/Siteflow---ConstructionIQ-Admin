import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../dashboard/dashboard_controller.dart';
import '../../models/manager_attendance_model.dart';

class ManagerAttendanceController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ManagerAttendanceResponse? _data;
  ManagerAttendanceResponse? get data => _data;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  int _currentPage = 0;
  int _totalPages = 1;
  bool get hasMore => _currentPage < _totalPages;

  List<dynamic> _managersList = [];
  List<dynamic> get managersList => _managersList;

  // Filters
  String? _fromDate;
  String? get fromDate => _fromDate;

  String? _toDate;
  String? get toDate => _toDate;

  String? _selectedManager;
  String? get selectedManager => _selectedManager;

  ManagerAttendanceController() {
    _initDefaultTodayDate();
  }

  void _initDefaultTodayDate() {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _fromDate = todayStr;
    _toDate = todayStr;
  }

  String _buildUrl(int page) {
    final queryParams = <String>['page=$page', 'page_size=25'];
    if (_fromDate != null && _fromDate!.isNotEmpty) queryParams.add('from=$_fromDate');
    if (_toDate != null && _toDate!.isNotEmpty) queryParams.add('to=$_toDate');
    if (_selectedManager != null && _selectedManager!.isNotEmpty) queryParams.add('manager=$_selectedManager');
    return '${ApiEndpoints.baseUrl}/manager-attendance/?${queryParams.join('&')}';
  }

  void _setPagination(ManagerAttendanceResponse response) {
    _currentPage = response.pagination['page'] is int ? response.pagination['page'] as int : int.tryParse('${response.pagination['page']}') ?? 1;
    _totalPages = response.pagination['total_pages'] is int ? response.pagination['total_pages'] as int : int.tryParse('${response.pagination['total_pages']}') ?? 1;
  }

  Future<void> fetchManagerAttendance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(_buildUrl(1));
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _data = ManagerAttendanceResponse.fromJson(decodedData);
        _setPagination(_data!);
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch manager attendance';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore || _data == null) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final response = await ApiClient.get(_buildUrl(_currentPage + 1));
      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200 && decodedData['status'] == true) {
        final next = ManagerAttendanceResponse.fromJson(decodedData);
        _data = ManagerAttendanceResponse(
          status: next.status, message: next.message, kpi: next.kpi,
          filters: next.filters, pagination: next.pagination,
          data: [..._data!.data, ...next.data],
        );
        _setPagination(next);
      }
    } catch (_) {
      // Preserve the records already loaded if another page fails.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchFilterOptions() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/manager-attendance/filters/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _managersList = decodedData['filters']?['managers'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching filters: $e");
    }
  }

  Future<Map<String, dynamic>> clockAction(String action) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/manager-attendance/clock/';
      final payload = {
        "action": action,
        "latitude": "53.3498053", // Mocked Dublin
        "longitude": "-6.2603097",
      };

      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          await fetchManagerAttendance(); // refresh the data and KPI
          DashboardController.triggerGlobalRefresh();
          return {"success": true, "message": decodedData['message'] ?? "Action successful."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to perform action."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  void setDateRange(String? from, String? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void setManager(String? managerId) {
    _selectedManager = managerId;
    notifyListeners();
  }

  void resetFilters() {
    _initDefaultTodayDate();
    _selectedManager = null;
    notifyListeners();
  }
}
