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

  // Unfiltered cache for instant 0ms Reset
  List<JobSheet> _cachedUnfilteredJobSheets = [];
  int _cachedUnfilteredTotalCount = 0;
  int _cachedUnfilteredTotalPages = 1;
  Map<String, dynamic> _cachedUnfilteredFilterOptions = {};

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

  bool get hasActiveFilters =>
      _selectedStatus != 'Status: All' && _selectedStatus != 'All' ||
      (_selectedProject?.isNotEmpty ?? false) ||
      (_selectedSheetNo?.isNotEmpty ?? false) ||
      (_selectedClient?.isNotEmpty ?? false) ||
      (_selectedOperative?.isNotEmpty ?? false) ||
      (_selectedForm?.isNotEmpty ?? false);

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

  String _parseFriendlyError(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('connection abort') ||
        str.contains('socketexception') ||
        str.contains('connection reset') ||
        str.contains('connection refused') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('clientexception') ||
        str.contains('handshakeexception')) {
      return 'Unable to load job sheets. Please check your connection and tap Retry.';
    }
    if (str.contains('timeoutexception') || str.contains('timed out')) {
      return 'Request timed out while loading job sheets. Please tap Retry.';
    }
    if (str.contains('formatexception') || str.contains('syntaxerror')) {
      return 'Unexpected response from server. Please tap Retry.';
    }
    return 'Unable to load job sheets. Please check your connection and tap Retry.';
  }

  bool _isRetryableNetworkError(dynamic e) {
    final str = e.toString().toLowerCase();
    return str.contains('connection abort') ||
        str.contains('socketexception') ||
        str.contains('timeoutexception') ||
        str.contains('timed out') ||
        str.contains('clientexception') ||
        str.contains('connection reset');
  }

  Future<void> fetchJobSheets({String? projectId, bool silent = false, bool keepPreviousData = false}) async {
    if (!silent && !keepPreviousData && _jobSheets.isEmpty) {
      _isLoading = true;
    }
    _errorMessage = null;
    if (!keepPreviousData && !silent && _jobSheets.isEmpty) {
      _currentPage = 0;
      _totalPages = 1;
    }
    notifyListeners();

    try {
      final url = await _buildUrl(page: 1, projectId: projectId);
      
      // Attempt request with 1 automatic retry on transient socket/connection drops
      dynamic response;
      try {
        response = await ApiClient.get(url).timeout(const Duration(seconds: 40));
      } catch (firstErr) {
        if (_isRetryableNetworkError(firstErr)) {
          await Future.delayed(const Duration(milliseconds: 600));
          response = await ApiClient.get(url).timeout(const Duration(seconds: 40));
        } else {
          rethrow;
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final jobSheetResponse = JobSheetResponse.fromJson(data);
        _jobSheets = jobSheetResponse.data;
        _currentPage = jobSheetResponse.page;
        _totalPages = jobSheetResponse.totalPages;
        _totalCount = jobSheetResponse.count;
        _mergeFilterOptions(jobSheetResponse.filterOptions);

        if (!hasActiveFilters && projectId == null) {
          _cachedUnfilteredJobSheets = List.from(_jobSheets);
          _cachedUnfilteredTotalCount = _totalCount;
          _cachedUnfilteredTotalPages = _totalPages;
          _cachedUnfilteredFilterOptions = Map.from(_filterOptions);
        }
      } else {
        if (_jobSheets.isEmpty) {
          final serverMsg = data['message']?.toString();
          _errorMessage = (serverMsg != null && serverMsg.isNotEmpty)
              ? serverMsg
              : 'Unable to load job sheets. Please tap Retry.';
        }
      }
    } catch (e) {
      if (_jobSheets.isEmpty) {
        _errorMessage = _parseFriendlyError(e);
      }
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
    fetchJobSheets(keepPreviousData: true);
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
    fetchJobSheets(keepPreviousData: true);
  }

  void clearFilters() {
    _selectedStatus = 'Status: All';
    _selectedProject = null;
    _selectedSheetNo = null;
    _selectedClient = null;
    _selectedOperative = null;
    _selectedForm = null;

    if (_cachedUnfilteredJobSheets.isNotEmpty) {
      // Instantly restore cached unfiltered items with 0ms latency
      _jobSheets = List.from(_cachedUnfilteredJobSheets);
      _totalCount = _cachedUnfilteredTotalCount;
      _totalPages = _cachedUnfilteredTotalPages;
      _currentPage = 1;
      _errorMessage = null;
      _isLoading = false;
      if (_cachedUnfilteredFilterOptions.isNotEmpty) {
        _filterOptions = Map.from(_cachedUnfilteredFilterOptions);
      }
      notifyListeners();

      // Silent background fetch to ensure freshness
      fetchJobSheets(silent: true);
    } else {
      fetchJobSheets(keepPreviousData: true);
    }
  }
}
