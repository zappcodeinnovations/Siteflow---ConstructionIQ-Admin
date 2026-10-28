import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/absence_management_model.dart';
import '../dashboard/dashboard_controller.dart';

class AbsenceManagementController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AbsenceRecord> _absences = [];
  List<AbsenceRecord> get absences => _absences;

  AbsenceSummary _summary = const AbsenceSummary();
  AbsenceSummary get summary => _summary;

  AbsenceFilterOptions _options = const AbsenceFilterOptions();
  AbsenceFilterOptions get options => _options;

  // Filter states
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _statusFilter = 'all';
  String get statusFilter => _statusFilter;

  String? _selectedType;
  String? get selectedType => _selectedType;

  int? _selectedProjectId;
  int? get selectedProjectId => _selectedProjectId;

  int? _selectedOperativeId;
  int? get selectedOperativeId => _selectedOperativeId;

  String? _fromDate;
  String? get fromDate => _fromDate;

  String? _toDate;
  String? get toDate => _toDate;

  String _sort = 'newest';
  String get sort => _sort;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _statusFilter != 'all' ||
      _selectedType != null ||
      _selectedProjectId != null ||
      _selectedOperativeId != null ||
      _fromDate != null ||
      _toDate != null;

  String _buildUrl() {
    final queryParams = <String>[];
    if (_searchQuery.trim().isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(_searchQuery.trim())}');
    }
    if (_statusFilter.isNotEmpty && _statusFilter != 'all') {
      queryParams.add('status=$_statusFilter');
    }
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      queryParams.add('absence_type=$_selectedType');
    }
    if (_selectedProjectId != null) {
      queryParams.add('project=$_selectedProjectId');
    }
    if (_selectedOperativeId != null) {
      queryParams.add('operative=$_selectedOperativeId');
    }
    if (_fromDate != null && _fromDate!.isNotEmpty) {
      queryParams.add('from=$_fromDate');
    }
    if (_toDate != null && _toDate!.isNotEmpty) {
      queryParams.add('to=$_toDate');
    }
    if (_sort.isNotEmpty) {
      queryParams.add('sort=$_sort');
    }

    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    return '${ApiEndpoints.baseUrl}/operative-absences/$query';
  }

  Future<void> fetchAbsences({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await ApiClient.get(_buildUrl());
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && decoded['status'] == true) {
        final rawList = decoded['data'] as List<dynamic>? ?? [];
        _absences = rawList
            .map((item) => AbsenceRecord.fromJson(item as Map<String, dynamic>))
            .toList();

        _summary = AbsenceSummary.fromJson(decoded['summary'] as Map<String, dynamic>?);
        _options = AbsenceFilterOptions.fromJson(decoded['options'] as Map<String, dynamic>?);
        _errorMessage = null;
      } else {
        _errorMessage = decoded['message']?.toString() ?? 'Failed to load absence records.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    notifyListeners();
    fetchAbsences();
  }

  void setDateRange(String? from, String? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
    fetchAbsences();
  }

  void setAdvancedFilters({
    String? absenceType,
    int? projectId,
    int? operativeId,
    String? sort,
  }) {
    _selectedType = absenceType;
    _selectedProjectId = projectId;
    _selectedOperativeId = operativeId;
    if (sort != null) _sort = sort;
    notifyListeners();
    fetchAbsences();
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _selectedType = null;
    _selectedProjectId = null;
    _selectedOperativeId = null;
    _fromDate = null;
    _toDate = null;
    _sort = 'newest';
    notifyListeners();
    fetchAbsences();
  }

  Future<Map<String, dynamic>> approveAbsence(int absenceId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.patch(
        '${ApiEndpoints.baseUrl}/operative-absences/$absenceId/',
        body: const {'status': 'approved'},
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['status'] == true) {
        await fetchAbsences(showLoading: false);
        DashboardController.triggerGlobalRefresh();
        return {'success': true, 'message': decoded['message'] ?? 'Absence approved successfully.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Unable to approve absence.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> rejectAbsence(int absenceId, String reason) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return {'success': false, 'message': 'Rejection reason is required.'};
    }

    _isActionLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.patch(
        '${ApiEndpoints.baseUrl}/operative-absences/$absenceId/',
        body: {
          'status': 'rejected',
          'rejection_reason': cleanReason,
        },
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['status'] == true) {
        await fetchAbsences(showLoading: false);
        DashboardController.triggerGlobalRefresh();
        return {'success': true, 'message': decoded['message'] ?? 'Absence rejected.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Unable to reject absence.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> cancelAbsence(int absenceId) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.patch(
        '${ApiEndpoints.baseUrl}/operative-absences/$absenceId/',
        body: const {'status': 'cancelled'},
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['status'] == true) {
        await fetchAbsences(showLoading: false);
        DashboardController.triggerGlobalRefresh();
        return {'success': true, 'message': decoded['message'] ?? 'Absence cancelled.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Unable to cancel absence.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> recordAbsence({
    required int operativeId,
    int? projectId,
    required String absenceType,
    required String startDate,
    required String endDate,
    bool isPartialDay = false,
    String reason = '',
    String notes = '',
  }) async {
    _isActionLoading = true;
    notifyListeners();
    try {
      final payload = <String, dynamic>{
        'operative_id': operativeId,
        'absence_type': absenceType,
        'start_date': startDate,
        'end_date': endDate,
        'is_partial_day': isPartialDay,
        'reason': reason,
        'notes': notes,
      };
      if (projectId != null && projectId > 0) {
        payload['project_id'] = projectId;
      }

      final response = await ApiClient.post(
        '${ApiEndpoints.baseUrl}/operative-absences/',
        body: payload,
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 && decoded['status'] == true) {
        await fetchAbsences(showLoading: false);
        DashboardController.triggerGlobalRefresh();
        return {'success': true, 'message': decoded['message'] ?? 'Absence recorded successfully.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Unable to record absence.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
