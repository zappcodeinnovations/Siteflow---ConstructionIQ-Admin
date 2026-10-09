import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Toggle view: 'member', 'team', 'project', 'reports'
  String _currentView = 'member';
  String get currentView => _currentView;

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Date Preset & Range
  String _datePreset = 'This Month';
  String get datePreset => _datePreset;

  String? _fromDate;
  String get fromDate => _fromDate ?? _getDefaultFromDate();
  String? _toDate;
  String get toDate => _toDate ?? _getDefaultToDate();

  // Multi-criteria filters
  String? _selectedClient;
  String? get selectedClient => _selectedClient;

  String? _selectedProject;
  String? get selectedProject => _selectedProject;

  String? _selectedTeam;
  String? get selectedTeam => _selectedTeam;

  String? _selectedMember;
  String? get selectedMember => _selectedMember;

  ProductivityController() {
    _applyDatePreset('This Month', notify: false);
  }

  String _getDefaultFromDate() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return DateFormat('dd/MM/yyyy').format(start);
  }

  String _getDefaultToDate() {
    final now = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  void _applyDatePreset(String preset, {bool notify = true}) {
    _datePreset = preset;
    final now = DateTime.now();
    if (preset == 'This Month') {
      final start = DateTime(now.year, now.month, 1);
      _fromDate = DateFormat('dd/MM/yyyy').format(start);
      _toDate = DateFormat('dd/MM/yyyy').format(now);
    } else if (preset == 'Last Month') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      _fromDate = DateFormat('dd/MM/yyyy').format(lastMonth);
      _toDate = DateFormat('dd/MM/yyyy').format(lastMonthEnd);
    } else if (preset == 'This Year') {
      final start = DateTime(now.year, 1, 1);
      _fromDate = DateFormat('dd/MM/yyyy').format(start);
      _toDate = DateFormat('dd/MM/yyyy').format(now);
    } else if (preset == 'All time') {
      _fromDate = null;
      _toDate = null;
    }
    if (notify) notifyListeners();
  }

  void setDatePreset(String preset) {
    _applyDatePreset(preset);
    fetchProductivity();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchProductivity() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String>[];
      if (_fromDate != null && _fromDate!.isNotEmpty) {
        queryParams.add('from=$_fromDate');
      }
      if (_toDate != null && _toDate!.isNotEmpty) {
        queryParams.add('to=$_toDate');
      }
      if (_selectedClient != null && _selectedClient!.isNotEmpty) {
        queryParams.add('client=$_selectedClient');
      }
      if (_selectedProject != null && _selectedProject!.isNotEmpty) {
        queryParams.add('project=$_selectedProject');
      }
      if (_selectedTeam != null && _selectedTeam!.isNotEmpty) {
        queryParams.add('team=$_selectedTeam');
      }
      if (_selectedMember != null && _selectedMember!.isNotEmpty) {
        queryParams.add('member=$_selectedMember');
      }

      final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final url = '${ApiEndpoints.baseUrl}/productivity/$query';

      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        _data = ProductivityResponse.fromJson(decodedData);
      } else {
        _errorMessage =
            decodedData['message'] ?? 'Failed to fetch productivity data';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setView(String view) {
    if (['member', 'team', 'project', 'reports'].contains(view)) {
      _currentView = view;
      notifyListeners();
    }
  }

  void setDateRange(String from, String to) {
    _datePreset = 'Custom';
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  void setFilters({
    String? client,
    String? project,
    String? team,
    String? member,
  }) {
    _selectedClient = client;
    _selectedProject = project;
    _selectedTeam = team;
    _selectedMember = member;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedClient = null;
    _selectedProject = null;
    _selectedTeam = null;
    _selectedMember = null;
    _applyDatePreset('This Month', notify: false);
    fetchProductivity();
  }

  List<MemberProductivity> get filteredMembers {
    if (_data == null) return [];
    final q = _searchQuery.toLowerCase().trim();
    return _data!.byMember.where((m) {
      if (q.isNotEmpty &&
          !m.name.toLowerCase().contains(q) &&
          !m.team.toLowerCase().contains(q)) {
        return false;
      }
      if (_selectedTeam != null &&
          _selectedTeam!.isNotEmpty &&
          m.team != _selectedTeam) {
        return false;
      }
      if (_selectedMember != null &&
          _selectedMember!.isNotEmpty &&
          m.name != _selectedMember) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TeamProductivity> get filteredTeams {
    if (_data == null) return [];
    final q = _searchQuery.toLowerCase().trim();
    return _data!.byTeam.where((t) {
      if (q.isNotEmpty && !t.team.toLowerCase().contains(q)) {
        return false;
      }
      if (_selectedTeam != null &&
          _selectedTeam!.isNotEmpty &&
          t.team != _selectedTeam) {
        return false;
      }
      return true;
    }).toList();
  }

  List<ProjectProductivity> get filteredProjects {
    if (_data == null) return [];
    final q = _searchQuery.toLowerCase().trim();
    return _data!.byProject.where((p) {
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.client.toLowerCase().contains(q)) {
        return false;
      }
      if (_selectedProject != null &&
          _selectedProject!.isNotEmpty &&
          p.name != _selectedProject) {
        return false;
      }
      if (_selectedClient != null &&
          _selectedClient!.isNotEmpty &&
          p.client != _selectedClient) {
        return false;
      }
      return true;
    }).toList();
  }
}
