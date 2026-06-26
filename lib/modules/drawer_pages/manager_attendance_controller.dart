import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/manager_attendance_model.dart';

class ManagerAttendanceController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ManagerAttendanceResponse? _data;
  ManagerAttendanceResponse? get data => _data;

  List<dynamic> _managersList = [];
  List<dynamic> get managersList => _managersList;

  // Filters
  String? _fromDate;
  String? get fromDate => _fromDate;

  String? _toDate;
  String? get toDate => _toDate;

  String? _selectedManager;
  String? get selectedManager => _selectedManager;

  Future<void> fetchManagerAttendance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.baseUrl + '/manager-attendance/';
      List<String> queryParams = [];

      if (_fromDate != null && _fromDate!.isNotEmpty) queryParams.add('from=$_fromDate');
      if (_toDate != null && _toDate!.isNotEmpty) queryParams.add('to=$_toDate');
      if (_selectedManager != null && _selectedManager!.isNotEmpty) queryParams.add('manager=$_selectedManager');

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _data = ManagerAttendanceResponse.fromJson(decodedData);
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

  Future<void> fetchFilterOptions() async {
    try {
      final url = ApiEndpoints.baseUrl + '/manager-attendance/filters/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _managersList = decodedData['filters']?['managers'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching filters: $e");
    }
  }

  Future<Map<String, dynamic>> clockAction(String action) async {
    try {
      final url = ApiEndpoints.baseUrl + '/manager-attendance/clock/';
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
    _fromDate = null;
    _toDate = null;
    _selectedManager = null;
    notifyListeners();
  }
}
