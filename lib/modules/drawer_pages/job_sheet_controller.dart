import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/date_helper.dart';
import '../../models/job_sheet_model.dart';

class JobSheetController extends ChangeNotifier {
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

  List<String> _allProjectsList = [];
  List<String> _allClientsList = [];
  List<String> _allFormsList = [];

  List<String> _extractList(dynamic rawList) {
    if (rawList is! List) return [];
    final set = <String>{};
    for (final item in rawList) {
      if (item == null) continue;
      if (item is Map) {
        final val = item['name'] ??
            item['title'] ??
            item['label'] ??
            item['project_name'] ??
            item['client_name'] ??
            item['sheet_no'] ??
            item['form_name'] ??
            item['operative_name'] ??
            item['username'] ??
            item['code'];
        if (val != null && val.toString().trim().isNotEmpty) {
          set.add(val.toString().trim());
        }
      } else if (item is String) {
        if (item.trim().isNotEmpty) set.add(item.trim());
      } else {
        final str = item.toString().trim();
        if (str.isNotEmpty) set.add(str);
      }
    }
    return set.toList();
  }

  List<String> get projectOptions {
    final set = <String>{};
    for (final key in ['projects', 'project_names', 'project', 'all_projects']) {
      set.addAll(_extractList(_filterOptions[key]));
    }
    for (final s in _jobSheets) {
      if (s.projectName.trim().isNotEmpty) set.add(s.projectName.trim());
    }
    for (final p in _allProjectsList) {
      if (p.trim().isNotEmpty) set.add(p.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get sheetNoOptions {
    final set = <String>{};
    for (final key in ['sheet_nos', 'sheets', 'sheet_no', 'sheetNos']) {
      set.addAll(_extractList(_filterOptions[key]));
    }
    for (final s in _jobSheets) {
      if (s.sheetNo.trim().isNotEmpty) set.add(s.sheetNo.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get clientOptions {
    final set = <String>{};
    for (final key in ['clients', 'client_names', 'client', 'all_clients']) {
      set.addAll(_extractList(_filterOptions[key]));
    }
    for (final s in _jobSheets) {
      if (s.clientName.trim().isNotEmpty) set.add(s.clientName.trim());
    }
    for (final c in _allClientsList) {
      if (c.trim().isNotEmpty) set.add(c.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get operativeOptions {
    final set = <String>{};
    for (final key in ['operatives', 'operative_names', 'operative', 'users']) {
      set.addAll(_extractList(_filterOptions[key]));
    }
    for (final s in _jobSheets) {
      if (s.operative.trim().isNotEmpty) set.add(s.operative.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get formOptions {
    final set = <String>{};
    for (final key in ['forms', 'form_names', 'form', 'form_types']) {
      set.addAll(_extractList(_filterOptions[key]));
    }
    for (final s in _jobSheets) {
      if (s.form.trim().isNotEmpty) set.add(s.form.trim());
    }
    for (final f in _allFormsList) {
      if (f.trim().isNotEmpty) set.add(f.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> fetchFilterMetadata() async {
    try {
      final futures = await Future.wait([
        ApiClient.get('${ApiEndpoints.baseUrl}${ApiEndpoints.projects}?page_size=100'),
        ApiClient.get('${ApiEndpoints.baseUrl}${ApiEndpoints.clients}?page_size=100'),
        ApiClient.get('${ApiEndpoints.baseUrl}${ApiEndpoints.libraryForms}?page_size=100'),
      ]);

      if (futures[0].statusCode == 200) {
        final data = jsonDecode(futures[0].body);
        final list = (data['data'] ?? data['results'] ?? data) as dynamic;
        _allProjectsList = _extractList(list);
      }
      if (futures[1].statusCode == 200) {
        final data = jsonDecode(futures[1].body);
        final list = (data['data'] ?? data['results'] ?? data) as dynamic;
        _allClientsList = _extractList(list);
      }
      if (futures[2].statusCode == 200) {
        final data = jsonDecode(futures[2].body);
        final list = (data['data'] ?? data['results'] ?? data) as dynamic;
        _allFormsList = _extractList(list);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchJobSheets({String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_allProjectsList.isEmpty) {
      fetchFilterMetadata();
    }

    try {
      final tz = await DateHelper.getDeviceTimezone();

      // Build query parameters
      String url = '${ApiEndpoints.baseUrl}/job-sheets/';
      List<String> queryParams = [];

      if (tz.isNotEmpty) {
        queryParams.add('tz=${Uri.encodeComponent(tz)}');
      }

      if (projectId != null && projectId.isNotEmpty) {
        queryParams.add('project=$projectId');
      } else if (_selectedProject != null && _selectedProject!.isNotEmpty) {
        queryParams.add('project=${Uri.encodeComponent(_selectedProject!)}');
      }

      String statusVal = _selectedStatus.replaceAll('Status: ', '').toLowerCase();
      if (statusVal != 'all') {
        queryParams.add('status=${Uri.encodeComponent(statusVal)}');
      }

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

      queryParams.add('page_size=100');

      if (queryParams.isNotEmpty) {
        url = '$url?${queryParams.join('&')}';
      }

      final response = await ApiClient.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final jobSheetResponse = JobSheetResponse.fromJson(data);
        _jobSheets = jobSheetResponse.data;
        _filterOptions = jobSheetResponse.filterOptions;
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
    fetchJobSheets();
  }

  void clearFilters() {
    _selectedStatus = 'Status: All';
    _selectedProject = null;
    _selectedSheetNo = null;
    _selectedClient = null;
    _selectedOperative = null;
    _selectedForm = null;
    fetchJobSheets();
  }
}
