import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../dashboard/dashboard_controller.dart';
import '../../models/manager_attendance_model.dart';
import 'package:geolocator/geolocator.dart';

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
  List<Map<String, dynamic>> _absences = [];
  List<Map<String, dynamic>> get absences => _absences;
  List<Map<String, dynamic>> _absenceOperatives = [];
  List<Map<String, dynamic>> get absenceOperatives => _absenceOperatives;
  List<Map<String, dynamic>> _absenceProjects = [];
  List<Map<String, dynamic>> get absenceProjects => _absenceProjects;

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

  Future<void> fetchAbsences() async {
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/operative-absences/',
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['status'] == true) {
        _absences = List<Map<String, dynamic>>.from(decoded['data'] ?? const []);
        final options = decoded['options'] as Map<String, dynamic>? ?? const {};
        _absenceOperatives = List<Map<String, dynamic>>.from(options['operatives'] ?? const []);
        _absenceProjects = List<Map<String, dynamic>>.from(options['projects'] ?? const []);
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Unable to load operative absences: $error');
    }
  }

  Future<Map<String, dynamic>> recordAbsence({
    required int operativeId,
    required int projectId,
    required String absenceType,
    required String startDate,
    required String endDate,
    required bool isPartialDay,
    String notes = '',
  }) async {
    try {
      final response = await ApiClient.post(
        '${ApiEndpoints.baseUrl}/operative-absences/',
        body: {
          'operative_id': operativeId,
          'project_id': projectId,
          'absence_type': absenceType,
          'start_date': startDate,
          'end_date': endDate,
          'is_partial_day': isPartialDay,
          'notes': notes,
        },
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && decoded['status'] == true) {
        await fetchAbsences();
        DashboardController.triggerGlobalRefresh();
        return {'success': true, 'message': decoded['message'] ?? 'Absence recorded.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Unable to record absence.'};
    } catch (error) {
      return {'success': false, 'message': 'Unable to record absence. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> cancelAbsence(int absenceId) async {
    try {
      final response = await ApiClient.patch(
        '${ApiEndpoints.baseUrl}/operative-absences/$absenceId/',
        body: const {'status': 'cancelled'},
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['status'] == true) {
        await fetchAbsences();
        DashboardController.triggerGlobalRefresh();
        return {'success': true, 'message': decoded['message'] ?? 'Absence cancelled.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Unable to cancel absence.'};
    } catch (_) {
      return {'success': false, 'message': 'Unable to cancel absence. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> clockAction(String action) async {
    try {
      double? lat;
      double? lon;
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          return {
            "success": false,
            "message": "Location services are disabled on your device. Please turn them on to clock attendance.",
          };
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return {
            "success": false,
            "message": "Location permission is required to clock attendance. Please grant permission in your settings.",
          };
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (locErr) {
        debugPrint("Location error during clock: $locErr");
      }

      if (lat == null || lon == null) {
        return {
          "success": false,
          "message": "Unable to acquire current location. Please verify GPS signal and try again.",
        };
      }

      final url = '${ApiEndpoints.baseUrl}/manager-attendance/clock/';
      final payload = {
        "action": action,
        "latitude": lat.toStringAsFixed(7),
        "longitude": lon.toStringAsFixed(7),
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
