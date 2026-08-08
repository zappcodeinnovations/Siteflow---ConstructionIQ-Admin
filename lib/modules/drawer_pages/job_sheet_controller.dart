import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
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

  Future<void> fetchJobSheets({String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build query parameters
      String url = ApiEndpoints.baseUrl + '/job-sheets/';
      List<String> queryParams = [];

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
      if (_selectedForm != null && _selectedForm!.isNotEmpty) {
        queryParams.add('form=${Uri.encodeComponent(_selectedForm!)}');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
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
