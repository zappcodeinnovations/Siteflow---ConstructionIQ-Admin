import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../models/admin_activity_log_model.dart';

class AdminActivityLogsController extends ChangeNotifier {
  bool _isDisposed = false;

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ActivityLogKPI? _kpi;
  ActivityLogKPI? get kpi => _kpi;

  List<ActivityLog> _logs = [];
  List<ActivityLog> get logs => _logs;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  int _currentPage = 1;
  int _totalPages = 1;
  bool get hasMore => _currentPage < _totalPages;
  int totalCount = 0;

  // Filters
  Map<String, dynamic> _filterOptions = {};
  Map<String, dynamic> get filterOptions => _filterOptions;

  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> get managers => _managers;

  List<Map<String, dynamic>> get availableManagers {
    if (_managers.isNotEmpty) {
      return _managers;
    }

    if (_filterOptions['managers'] is List &&
        (_filterOptions['managers'] as List).isNotEmpty) {
      return (_filterOptions['managers'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }

  String? selectedManager;
  String? selectedRole;
  String? selectedModule;
  String? selectedAction;
  String? fromDate;
  String? toDate;
  String searchQuery = "";

  /// Manager/supervisor login: the backend returns only the operatives in
  /// the teams they lead, and the person filter lists those operatives.
  bool operativeScope = false;

  Future<void> initializeData() async {
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    operativeScope = await AuthService.canViewOperativeLogs();
    await Future.wait([
      fetchKPIs(),
      fetchFilterOptions(),
      // The members directory is admin-only; operatives come from the
      // filter-options endpoint instead.
      if (!operativeScope) fetchManagers(),
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
        _notifySafely();
      }
    } catch (e) {
      debugPrint("Error fetching Activity Log KPIs: $e");
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
        _notifySafely();
      }
    } catch (e) {
      debugPrint("Error fetching Activity Log filters: $e");
    }
  }

  Future<void> fetchManagers() async {
    try {
      // The activity-log filter is manager-specific.  Ask the API for that
      // role instead of downloading the whole member directory and trying to
      // infer roles on the device.
      final url =
          '${ApiEndpoints.baseUrl}/admin/members/?role=manager&page_size=1000';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decodedData is List) {
          list = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          if (decodedData['data'] is List) {
            list = decodedData['data'];
          } else if (decodedData['results'] is List) {
            list = decodedData['results'];
          } else if (decodedData['members'] is List) {
            list = decodedData['members'];
          }
        }

        final filteredManagers = list
            .where((item) {
              if (item is! Map) return false;
              final role =
                  (item['role'] ??
                          item['role_name'] ??
                          item['role_display_name'] ??
                          '')
                      .toString()
                      .toLowerCase();
              return role == 'manager';
            })
            .map((item) {
              final first = item['first_name']?.toString() ?? '';
              final last = item['last_name']?.toString() ?? '';
              final fullName = '$first $last'.trim();
              final displayName = item['display_name']?.toString() ?? '';
              final name = displayName.isNotEmpty
                  ? displayName
                  : (fullName.isNotEmpty
                        ? fullName
                        : item['email']?.toString() ?? '');
              return {
                'id': item['id'],
                'display_name': name,
                'name': name,
                'email': item['email'] ?? '',
                'role': item['role'] ?? item['role_name'] ?? 'Manager',
              };
            })
            .toList();

        if (filteredManagers.isNotEmpty) {
          _managers = filteredManagers;
          _notifySafely();
        }
      }
    } catch (e) {
      debugPrint("Error fetching managers for activity logs: $e");
    }
  }

  void updateFilters({
    String? manager,
    String? role,
    String? module,
    String? action,
    String? from,
    String? to,
    String? search,
  }) {
    if (manager != null) selectedManager = manager.isEmpty ? null : manager;
    if (role != null) selectedRole = role.isEmpty ? null : role;
    if (module != null) selectedModule = module.isEmpty ? null : module;
    if (action != null) selectedAction = action.isEmpty ? null : action;
    if (from != null) fromDate = from.isEmpty ? null : from;
    if (to != null) toDate = to.isEmpty ? null : to;
    if (search != null) searchQuery = search;

    fetchLogs();
  }

  void resetFilters() {
    selectedManager = null;
    selectedRole = null;
    selectedModule = null;
    selectedAction = null;
    fromDate = null;
    toDate = null;
    searchQuery = "";
    fetchLogs();
  }

  String _buildLogsUrl(int page) {
    List<String> queryParams = ['page=$page', 'page_size=50'];

    if (selectedManager != null && selectedManager!.isNotEmpty) {
      queryParams.add('user_id=$selectedManager');
    }
    if (selectedRole != null && selectedRole!.isNotEmpty) {
      queryParams.add('role=$selectedRole');
    }
    if (selectedModule != null && selectedModule!.isNotEmpty) {
      queryParams.add('module=$selectedModule');
    }
    if (selectedAction != null && selectedAction!.isNotEmpty) {
      queryParams.add('action_type=$selectedAction');
    }
    if (fromDate != null && fromDate!.isNotEmpty) {
      queryParams.add('from=$fromDate');
    }
    if (toDate != null && toDate!.isNotEmpty) queryParams.add('to=$toDate');
    if (searchQuery.isNotEmpty) queryParams.add('search=$searchQuery');

    return '${ApiEndpoints.baseUrl}/admin/activity-logs/?${queryParams.join('&')}';
  }

  Future<void> fetchLogs({bool isInitial = false}) async {
    if (!isInitial) {
      _isLoading = true;
      _errorMessage = null;
      _notifySafely();
    }
    _currentPage = 1;
    _totalPages = 1;

    try {
      final response = await ApiClient.get(_buildLogsUrl(1));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final dataList = (decoded['data'] as List?) ?? [];
          _logs = dataList
              .map((i) => ActivityLog.fromJson(i as Map<String, dynamic>))
              .toList();
          _currentPage = decoded['page'] is int ? decoded['page'] as int : 1;
          _totalPages = decoded['total_pages'] is int
              ? decoded['total_pages'] as int
              : 1;
          totalCount = decoded['count'] is int
              ? decoded['count'] as int
              : _logs.length;
        }
        _errorMessage = null;
      } else {
        _errorMessage =
            'Failed to load activity logs (${response.statusCode}).';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  /// Without this, the list only ever showed the API's default page (20
  /// records) regardless of how many logs actually existed (e.g. 109) - the
  /// response's page/total_pages/count were never even read before.
  Future<void> loadMoreLogs() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    _notifySafely();
    try {
      final response = await ApiClient.get(_buildLogsUrl(_currentPage + 1));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final dataList = (decoded['data'] as List?) ?? [];
          _logs = [
            ..._logs,
            ...dataList.map(
              (i) => ActivityLog.fromJson(i as Map<String, dynamic>),
            ),
          ];
          _currentPage = decoded['page'] is int
              ? decoded['page'] as int
              : _currentPage + 1;
          _totalPages = decoded['total_pages'] is int
              ? decoded['total_pages'] as int
              : _totalPages;
          totalCount = decoded['count'] is int
              ? decoded['count'] as int
              : totalCount;
        }
      }
    } catch (_) {
      // Keep what's already loaded visible if a later page fails.
    } finally {
      _isLoadingMore = false;
      _notifySafely();
    }
  }

  String? exportError;

  /// Downloads the export through the authenticated API client and stores it
  /// in the app's shared download history.
  Future<bool> exportLogs(String format) async {
    exportError = null;
    try {
      String url =
          '${ApiEndpoints.baseUrl}/admin/activity-logs/export/?format=$format';
      if (selectedManager != null && selectedManager!.isNotEmpty) {
        url += '&user_id=$selectedManager';
      }
      if (selectedRole != null && selectedRole!.isNotEmpty) {
        url += '&role=$selectedRole';
      }
      if (selectedModule != null && selectedModule!.isNotEmpty) {
        url += '&module=$selectedModule';
      }
      if (selectedAction != null && selectedAction!.isNotEmpty) {
        url += '&action_type=$selectedAction';
      }
      if (fromDate != null && fromDate!.isNotEmpty) url += '&from=$fromDate';
      if (toDate != null && toDate!.isNotEmpty) url += '&to=$toDate';
      if (searchQuery.isNotEmpty) url += '&search=$searchQuery';

      final ext = format == 'excel' ? 'xlsx' : format;
      final mimeType = switch (ext) {
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'pdf' => 'application/pdf',
        _ => 'text/csv',
      };
      final result = await DownloadManager.instance.downloadUrl(
        url: url,
        fileName: 'activity_logs_${DateTime.now().millisecondsSinceEpoch}.$ext',
        mimeType: mimeType,
      );
      return result != null;
    } catch (e) {
      exportError = 'Export error: $e';
      debugPrint(exportError);
      return false;
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
      debugPrint("Error fetching log detail: $e");
    }
    return null;
  }
}
