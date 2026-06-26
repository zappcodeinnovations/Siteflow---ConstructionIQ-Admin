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

  Future<void> fetchJobSheets({String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build query parameters
      String url = ApiEndpoints.baseUrl + '/job-sheets/';
      if (projectId != null && projectId.isNotEmpty) {
        url += '?project=$projectId';
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
    notifyListeners();
    // Would trigger fetchJobSheets with new filter parameters here
  }
}
