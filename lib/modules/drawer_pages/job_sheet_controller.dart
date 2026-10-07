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

  Future<void> fetchJobSheets({String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build query parameters
      String url = '${ApiEndpoints.baseUrl}/job-sheets/';
      List<String> queryParams = [];

      final tz = await DateHelper.getDeviceTimezone();
      if (tz.isNotEmpty) {
        queryParams.add('tz=${Uri.encodeComponent(tz)}');
      }

      if (projectId != null && projectId.isNotEmpty) {
        queryParams.add('project=$projectId');
      } else if (_selectedProject != null && _selectedProject!.isNotEmpty) {
        queryParams.add('project=${Uri.encodeComponent(_selectedProject!)}');
      }

      String statusVal = _selectedStatus.replaceAll('Status: ', '').toLowerCase().trim();
      if (statusVal.isEmpty) statusVal = 'all';
      queryParams.add('status=${Uri.encodeComponent(statusVal)}');

      if (_selectedSheetNo != null && _selectedSheetNo!.isNotEmpty) {
        queryParams.add('sheet_no=${Uri.encodeComponent(_selectedSheetNo!)}');
      }
      if (_selectedClient != null && _selectedClient!.isNotEmpty) {
        queryParams.add('client=${Uri.encodeComponent(_selectedClient!)}');
      }
      if (_selectedOperative != null && _selectedOperative!.isNotEmpty) {
        queryParams.add('operative=${Uri.encodeComponent(_selectedOperative!)}');
      }
      if (dailyReportsMode) {
        queryParams.add('daily_reports=true');
        queryParams.add('form=${Uri.encodeComponent('Daily Diary')}');
      } else if (_selectedForm != null && _selectedForm!.isNotEmpty) {
        queryParams.add('form=${Uri.encodeComponent(_selectedForm!)}');
      }

      if (!queryParams.any((p) => p.startsWith('page_size='))) {
        queryParams.add('page_size=1000');
      }

      if (queryParams.isNotEmpty) {
        url = '$url?${queryParams.join('&')}';
      }

      final response = await ApiClient.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final jobSheetResponse = JobSheetResponse.fromJson(data);
        List<JobSheet> allSheets = List.from(jobSheetResponse.data);
        
        if (jobSheetResponse.filterOptions.isNotEmpty) {
          if (_filterOptions.isEmpty) {
            _filterOptions = Map<String, dynamic>.from(jobSheetResponse.filterOptions);
          } else {
            jobSheetResponse.filterOptions.forEach((k, v) {
              if (v is List && v.isNotEmpty) {
                final currentSet = ((_filterOptions[k] as List?) ?? []).toSet();
                currentSet.addAll(v);
                _filterOptions[k] = currentSet.toList();
              }
            });
          }
        }

        if (jobSheetResponse.totalPages > 1 && jobSheetResponse.page < jobSheetResponse.totalPages) {
          int currentPage = jobSheetResponse.page + 1;
          while (currentPage <= jobSheetResponse.totalPages) {
            String pageUrl = '$url${url.contains('?') ? '&' : '?'}page=$currentPage';
            final pageRes = await ApiClient.get(pageUrl);
            final pageData = jsonDecode(pageRes.body);
            if (pageRes.statusCode == 200 && pageData['status'] == true) {
              final nextResp = JobSheetResponse.fromJson(pageData);
              allSheets.addAll(nextResp.data);
            }
            currentPage++;
          }
        }

        _jobSheets = allSheets;
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
