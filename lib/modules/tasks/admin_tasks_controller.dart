import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/admin_task_model.dart';

/// Controller for the global Tasks screen.
///
/// Tasks are Jobs, not job-sheet submissions. Keeping this separate from
/// [JobSheetController] is important because task statuses include `awaiting`
/// while job-sheet statuses describe submission/review state.
class AdminTasksController extends ChangeNotifier {
  static const int _pageSize = 25;

  bool _disposed = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<AdminTaskModel> _tasks = const [];
  Map<String, List<String>> _filterOptions = const {};
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalCount = 0;
  int _requestVersion = 0;

  String _status = 'all';
  String? _project;
  String? _client;
  String? _operative;
  String _search = '';

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<AdminTaskModel> get tasks => List.unmodifiable(_tasks);
  Map<String, List<String>> get filterOptions =>
      Map.unmodifiable(_filterOptions);
  int get totalCount => _totalCount;
  bool get hasMore => _currentPage < _totalPages;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String _buildUrl(int page) {
    final params = <String, String>{
      'page': '$page',
      'page_size': '$_pageSize',
      if (_status != 'all') 'status': _status,
      if (_project?.isNotEmpty == true) 'project': _project!,
      if (_client?.isNotEmpty == true) 'client': _client!,
      if (_operative?.isNotEmpty == true) 'operative': _operative!,
      if (_search.isNotEmpty) 'search': _search,
    };
    return Uri.parse(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.adminTasks}',
    ).replace(queryParameters: params).toString();
  }

  Map<String, List<String>> _parseFilterOptions(dynamic raw) {
    if (raw is! Map) return const {};
    final options = <String, List<String>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! List) continue;
      options[entry.key.toString()] = value
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString().trim())
          .toList(growable: false);
    }
    return options;
  }

  int _asInt(dynamic value, int fallback) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

  Future<void> fetchTasks() async {
    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _tasks = const [];
    _currentPage = 0;
    _totalPages = 0;
    _totalCount = 0;
    notifyListeners();

    try {
      final response = await ApiClient.get(_buildUrl(1));
      final decoded = jsonDecode(response.body);
      if (requestVersion != _requestVersion) return;

      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['status'] == true) {
        final records = decoded['data'] as List? ?? const [];
        _tasks = records
            .whereType<Map>()
            .map(
              (task) =>
                  AdminTaskModel.fromJson(Map<String, dynamic>.from(task)),
            )
            .toList(growable: false);
        _currentPage = _asInt(decoded['page'], 1);
        _totalPages = _asInt(decoded['total_pages'], 1);
        _totalCount = _asInt(decoded['count'], _tasks.length);
        _filterOptions = _parseFilterOptions(decoded['filter_options']);
      } else {
        _errorMessage = decoded is Map
            ? decoded['message']?.toString() ?? 'Unable to load tasks.'
            : 'Unable to load tasks.';
      }
    } catch (_) {
      if (requestVersion == _requestVersion) {
        _errorMessage =
            'Unable to load tasks. Please check your connection and retry.';
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final requestVersion = ++_requestVersion;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await ApiClient.get(_buildUrl(_currentPage + 1));
      final decoded = jsonDecode(response.body);
      if (requestVersion != _requestVersion) return;

      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['status'] == true) {
        final records = decoded['data'] as List? ?? const [];
        final nextPage = records
            .whereType<Map>()
            .map(
              (task) =>
                  AdminTaskModel.fromJson(Map<String, dynamic>.from(task)),
            )
            .toList(growable: false);
        _tasks = [..._tasks, ...nextPage];
        _currentPage = _asInt(decoded['page'], _currentPage + 1);
        _totalPages = _asInt(decoded['total_pages'], _totalPages);
        _totalCount = _asInt(decoded['count'], _totalCount);
      }
    } catch (_) {
      // Retain the already rendered page if a later page cannot be fetched.
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> setFilters({
    required String status,
    String? project,
    String? client,
    String? operative,
    String search = '',
  }) async {
    _status = status.trim().isEmpty ? 'all' : status.trim().toLowerCase();
    _project = _nonEmpty(project);
    _client = _nonEmpty(client);
    _operative = _nonEmpty(operative);
    _search = search.trim();
    await fetchTasks();
  }

  Future<void> clearFilters() => setFilters(status: 'all');

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    try {
      final response = await ApiClient.delete(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.adminTaskDelete(taskId)}',
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['status'] == true) {
        await fetchTasks();
        return {
          'success': true,
          'message': decoded['message'] ?? 'Task deleted.',
        };
      }
      return {
        'success': false,
        'message': decoded is Map
            ? decoded['message'] ?? 'Unable to delete task.'
            : 'Unable to delete task.',
      };
    } catch (_) {
      return {'success': false, 'message': 'Unable to delete task.'};
    }
  }
}
