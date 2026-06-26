import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/productivity_model.dart';

class ProductivityController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProductivityResponse? _data;
  ProductivityResponse? get data => _data;

  // Toggle view: 'member', 'team', 'project'
  String _currentView = 'member';
  String get currentView => _currentView;

  // Filters
  String? _fromDate;
  String get fromDate => _fromDate ?? "01/06/2026";
  String? _toDate;
  String get toDate => _toDate ?? "22/06/2026";

  String? _selectedTeam;
  String? get selectedTeam => _selectedTeam;

  String? _selectedMember;
  String? get selectedMember => _selectedMember;

  String? _selectedProject;
  String? get selectedProject => _selectedProject;

  Future<void> fetchProductivity() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.baseUrl + '/productivity/?';
      List<String> queryParams = [];

      if (_fromDate != null) queryParams.add('from=$_fromDate');
      if (_toDate != null) queryParams.add('to=$_toDate');
      if (_selectedTeam != null && _selectedTeam!.isNotEmpty) queryParams.add('team=$_selectedTeam');
      if (_selectedMember != null && _selectedMember!.isNotEmpty) queryParams.add('member=$_selectedMember');
      if (_selectedProject != null && _selectedProject!.isNotEmpty) queryParams.add('project=$_selectedProject');
      
      url += queryParams.join('&');

      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _data = ProductivityResponse.fromJson(decodedData);
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch productivity data';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setView(String view) {
    if (['member', 'team', 'project'].contains(view)) {
      _currentView = view;
      notifyListeners();
    }
  }

  void setDateRange(String from, String to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void setTeam(String? team) {
    _selectedTeam = team;
    notifyListeners();
  }

  void setMember(String? member) {
    _selectedMember = member;
    notifyListeners();
  }

  void setProject(String? project) {
    _selectedProject = project;
    notifyListeners();
  }
}
