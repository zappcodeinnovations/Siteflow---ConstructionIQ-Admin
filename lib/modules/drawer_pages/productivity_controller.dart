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

  // Date range: either a named period ('today', 'this_week', 'this_month',
  // 'this_year') or 'custom' with explicit fromDate/toDate. Defaults to
  // "This Month" to match the web admin portal's default preset.
  String _period = 'this_month';
  String get period => _period;

  String? _fromDate;
  String get fromDate => _fromDate ?? '';
  String? _toDate;
  String get toDate => _toDate ?? '';

  static const Map<String, String> periodLabels = {
    'today': 'Today',
    'this_week': 'This Week',
    'this_month': 'This Month',
    'this_year': 'This Year',
    'custom': 'Custom',
  };

  String get periodLabel {
    if (_period == 'custom' && _fromDate != null && _toDate != null) {
      return '$_fromDate - $_toDate';
    }
    return periodLabels[_period] ?? 'This Month';
  }

  String? _selectedClient;
  String? get selectedClient => _selectedClient;

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

      if (_period == 'custom' && _fromDate != null && _toDate != null) {
        queryParams.add('from=$_fromDate');
        queryParams.add('to=$_toDate');
      } else {
        queryParams.add('period=$_period');
      }
      if (_selectedClient != null && _selectedClient!.isNotEmpty) queryParams.add('client=$_selectedClient');
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

  void setPeriod(String period) {
    _period = period;
    if (period != 'custom') {
      _fromDate = null;
      _toDate = null;
    }
    notifyListeners();
  }

  void setDateRange(String from, String to) {
    _period = 'custom';
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void setClient(String? client) {
    _selectedClient = client;
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
