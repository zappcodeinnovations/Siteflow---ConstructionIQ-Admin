import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_activity_log_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminActivityLogsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ActivityLogKPI? _kpi;
  ActivityLogKPI? get kpi => _kpi;

  List<ActivityLog> _logs = [];
  List<ActivityLog> get logs => _logs;

  // Filters
  Map<String, dynamic> _filterOptions = {};
  Map<String, dynamic> get filterOptions => _filterOptions;

  String? selectedManager;
  String? selectedModule;
  String? selectedAction;
  String? fromDate;
  String? toDate;
  String searchQuery = "";

  Future<void> initializeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait([
      fetchKPIs(),
      fetchFilterOptions(),
      fetchLogs(isInitial: true),
    ]);
  }

  Future<void> fetchKPIs() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/activity-logs/kpis/';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
           if (decoded.containsKey('data')) {
              _kpi = ActivityLogKPI.fromJson(decoded['data']);
           } else if (decoded.containsKey('kpis')) {
              _kpi = ActivityLogKPI.fromJson(decoded['kpis']);
           } else {
              _kpi = ActivityLogKPI.fromJson(decoded);
           }
        }
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching Activity Log KPIs: $e");
    }
  }

  Future<void> fetchFilterOptions() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/activity-logs/filter-options/';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
           if (decoded.containsKey('data')) {
              _filterOptions = decoded['data'];
           } else if (decoded.containsKey('filters')) {
              _filterOptions = decoded['filters'];
           } else {
              _filterOptions = decoded;
           }
        }
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching Activity Log filters: $e");
    }
  }

  void updateFilters({
    String? manager,
    String? module,
    String? action,
    String? from,
    String? to,
    String? search,
  }) {
    if (manager != null) selectedManager = manager.isEmpty ? null : manager;
    if (module != null) selectedModule = module.isEmpty ? null : module;
    if (action != null) selectedAction = action.isEmpty ? null : action;
    if (from != null) fromDate = from.isEmpty ? null : from;
    if (to != null) toDate = to.isEmpty ? null : to;
    if (search != null) searchQuery = search;
    
    fetchLogs();
  }

  void resetFilters() {
    selectedManager = null;
    selectedModule = null;
    selectedAction = null;
    fromDate = null;
    toDate = null;
    searchQuery = "";
    fetchLogs();
  }

  Future<void> fetchLogs({bool isInitial = false}) async {
    if (!isInitial) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      List<String> queryParams = [];
      
      if (selectedManager != null) queryParams.add('user_id=$selectedManager');
      if (selectedModule != null) queryParams.add('module=$selectedModule');
      if (selectedAction != null) queryParams.add('action_type=$selectedAction');
      if (fromDate != null) queryParams.add('from=$fromDate');
      if (toDate != null) queryParams.add('to=$toDate');
      if (searchQuery.isNotEmpty) queryParams.add('search=$searchQuery');

      final String url = queryParams.isNotEmpty
          ? '${ApiEndpoints.baseUrl}/admin/activity-logs/?${queryParams.join('&')}'
          : '${ApiEndpoints.baseUrl}/admin/activity-logs/';

      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> dataList = [];

        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          final data = decoded['data'] ?? decoded['results'] ?? decoded['logs'];
          if (data is List) {
            dataList = data;
          } else if (data is Map<String, dynamic>) {
            dataList = (data['results'] ?? data['logs'] ?? data['data']) as List? ?? [];
          }
        }

        _logs = dataList.map((i) => ActivityLog.fromJson(i as Map<String, dynamic>)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load activity logs (${response.statusCode}).';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> exportLogs(String format) async {
    try {
      String url = '${ApiEndpoints.baseUrl}/admin/activity-logs/export/?format=$format';
      if (selectedManager != null) url += '&user_id=$selectedManager';
      if (selectedModule != null) url += '&module=$selectedModule';
      if (selectedAction != null) url += '&action_type=$selectedAction';
      if (fromDate != null) url += '&from=$fromDate';
      if (toDate != null) url += '&to=$toDate';

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print("Could not launch $url");
      }
    } catch (e) {
      print("Export error: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchLogDetails(int logId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/activity-logs/$logId/';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
           if (decoded.containsKey('data')) {
              return decoded['data'];
           }
           return decoded;
        }
      }
    } catch (e) {
      print("Error fetching log detail: $e");
    }
    return null;
  }
}
