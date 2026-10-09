import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/date_helper.dart';
import '../../models/job_sheet_model.dart';

class JobSheetController extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int _currentPage = 0;
  int _totalPages = 1;
  int _totalCount = 0;
  bool get hasMore => _currentPage < _totalPages;
  int get totalCount => _totalCount;
  static const int _pageSize = 25;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<JobSheet> _jobSheets = [];
  List<JobSheet> get jobSheets => _jobSheets;

  Map<String, dynamic> _filterOptions = {};
  Map<String, dynamic> get filterOptions => _filterOptions;

  // Selected filters
  String _selectedStatus = 'Status: All';
  String get selectedStatus => _selectedStatus;

  String? _selectedProject;
  String? get selectedProject => _selectedProject;

  String? _selectedSheetNo;
  String? get selectedSheetNo => _selectedSheetNo;

  String? _selectedClient;
  String? get selectedClient => _selectedClient;

  String? _selectedOperative;
  String? get selectedOperative => _selectedOperative;

  String? _selectedForm;
  String? get selectedForm => _selectedForm;

  // When true, this controller serves the "Daily Reports" screen instead of
  // "Job Sheets": Daily Diary submissions are included (the default list
  // excludes them) and locked as the only form shown, mirroring the web's
  // separate /daily-reports/ URL which reuses the same job_sheets_list view.
  bool dailyReportsMode = false;

  Future<String> _buildUrl({required int page, String? projectId}) async {
    String url = '${ApiEndpoints.baseUrl}/job-sheets/';
    final queryParams = <String>['page=$page', 'page_size=$_pageSize'];

    final tz = await DateHelper.getDeviceTimezone();
    if (tz.isNotEmpty) queryParams.add('tz=${Uri.encodeComponent(tz)}');
    if (projectId != null && projectId.isNotEmpty) {
      queryParams.add('project=$projectId');
    } else if (_selectedProject != null && _selectedProject!.isNotEmpty) {
      queryParams.add('project=${Uri.encodeComponent(_selectedProject!)}');
    }

    var statusVal = _selectedStatus.replaceAll('Status: ', '').toLowerCase().trim();
    if (statusVal.isEmpty) statusVal = 'all';
    queryParams.add('status=${Uri.encodeComponent(statusVal)}');
    if (_selectedSheetNo?.isNotEmpty == true) queryParams.add('sheet_no=${Uri.encodeComponent(_selectedSheetNo!)}');
    if (_selectedClient?.isNotEmpty == true) queryParams.add('client=${Uri.encodeComponent(_selectedClient!)}');
    if (_selectedOperative?.isNotEmpty == true) queryParams.add('operative=${Uri.encodeComponent(_selectedOperative!)}');
    if (dailyReportsMode) {
      queryParams.add('daily_reports=true');
      queryParams.add('form=${Uri.encodeComponent('Daily Diary')}');
    } else if (_selectedForm?.isNotEmpty == true) {
      queryParams.add('form=${Uri.encodeComponent(_selectedForm!)}');
    }
    return '$url?${queryParams.join('&')}';
  }

  void _mergeFilterOptions(Map<String, dynamic> options) {
    if (options.isEmpty) return;
    if (_filterOptions.isEmpty) {
      _filterOptions = Map<String, dynamic>.from(options);
      return;
    }
    options.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        _filterOptions[key] = { ...((_filterOptions[key] as List?) ?? []), ...value }.toList();
      }
    });
  }

  Future<void> fetchJobSheets({String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 0;
    _totalPages = 1;
    notifyListeners();

    try {
      final response = await ApiClient.get(await _buildUrl(page: 1, projectId: projectId));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final jobSheetResponse = JobSheetResponse.fromJson(data);
        _jobSheets = jobSheetResponse.data;
        _currentPage = jobSheetResponse.page;
        _totalPages = jobSheetResponse.totalPages;
        _totalCount = jobSheetResponse.count;
        _mergeFilterOptions(jobSheetResponse.filterOptions);
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch job sheets';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore({String? projectId}) async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final response = await ApiClient.get(await _buildUrl(page: _currentPage + 1, projectId: projectId));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final page = JobSheetResponse.fromJson(data);
        _jobSheets = [..._jobSheets, ...page.data];
        _currentPage = page.page;
        _totalPages = page.totalPages;
        _totalCount = page.count;
        _mergeFilterOptions(page.filterOptions);
      }
    } catch (_) {
      // Keep the first loaded page usable if a later page cannot be fetched.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    _jobSheets = [];
    fetchJobSheets();
  }

  void setFilter({
    String? project,
    String? sheetNo,
    String? client,
    String? operative,
    String? form,
  }) {
    _selectedProject = project;
    _selectedSheetNo = sheetNo;
    _selectedClient = client;
    _selectedOperative = operative;
    _selectedForm = form;
    _jobSheets = [];
    fetchJobSheets();
  }

  void clearFilters() {
    _selectedStatus = 'Status: All';
    _selectedProject = null;
    _selectedSheetNo = null;
    _selectedClient = null;
    _selectedOperative = null;
    _selectedForm = null;
    _jobSheets = [];
    fetchJobSheets();
  }
}
