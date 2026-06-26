import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/timesheet_model.dart';

class TimesheetController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TimesheetResponse? _data;
  TimesheetResponse? get data => _data;

  // Filters
  String? _fromDate;
  String? get fromDate => _fromDate;

  String? _toDate;
  String? get toDate => _toDate;

  String? _selectedOperator;
  String? get selectedOperator => _selectedOperator;

  String? _selectedProject;
  String? get selectedProject => _selectedProject;

  String? _selectedAttendanceStatus;
  String? get selectedAttendanceStatus => _selectedAttendanceStatus;

  String? _selectedShiftRule;
  String? get selectedShiftRule => _selectedShiftRule;

  Future<void> fetchTimesheets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.baseUrl + '/timesheets/?';
      List<String> queryParams = [];

      if (_fromDate != null && _fromDate!.isNotEmpty) queryParams.add('from=$_fromDate');
      if (_toDate != null && _toDate!.isNotEmpty) queryParams.add('to=$_toDate');
      if (_selectedOperator != null && _selectedOperator!.isNotEmpty) queryParams.add('operator=$_selectedOperator');
      if (_selectedProject != null && _selectedProject!.isNotEmpty) queryParams.add('project=$_selectedProject');
      if (_selectedAttendanceStatus != null && _selectedAttendanceStatus!.isNotEmpty) queryParams.add('attendance_status=$_selectedAttendanceStatus');
      if (_selectedShiftRule != null && _selectedShiftRule!.isNotEmpty) queryParams.add('shift_rule=$_selectedShiftRule');

      url += queryParams.join('&');

      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _data = TimesheetResponse.fromJson(decodedData);
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch timesheets';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addAttendance(Map<String, dynamic> payload) async {
    try {
      final url = ApiEndpoints.baseUrl + '/timesheets/add/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          // Success, reload data
          await fetchTimesheets();
          return {"success": true, "message": decodedData['message'] ?? "Attendance added successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to add attendance."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  void setDateRange(String? from, String? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void setAdvancedFilters({
    String? op,
    String? project,
    String? status,
    String? shift,
  }) {
    _selectedOperator = op;
    _selectedProject = project;
    _selectedAttendanceStatus = status;
    _selectedShiftRule = shift;
    notifyListeners();
  }

  void resetFilters() {
    _fromDate = null;
    _toDate = null;
    _selectedOperator = null;
    _selectedProject = null;
    _selectedAttendanceStatus = null;
    _selectedShiftRule = null;
    notifyListeners();
  }
}
