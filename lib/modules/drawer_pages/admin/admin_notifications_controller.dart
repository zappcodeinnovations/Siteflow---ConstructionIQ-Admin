import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_notification_model.dart';

class AdminNotificationsController extends ChangeNotifier {
  List<AdminNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _activeSearch = '';
  String? _activeAudience;

  int _pageSize = 50;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoadingMore = false;
  int _requestVersion = 0;

  List<AdminNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _totalPages;
  String? get errorMessage => _errorMessage;

  String _pageUrl(int page) {
    final query = <String, String>{'page': '$page', 'page_size': '$_pageSize'};
    if (_activeSearch.isNotEmpty) query['search'] = _activeSearch;
    if (_activeAudience != null) query['audience'] = _activeAudience!;
    return Uri.parse(
      '${ApiEndpoints.baseUrl}/admin/notifications/',
    ).replace(queryParameters: query).toString();
  }

  int _asInt(dynamic value, int fallback) =>
      value is int ? value : int.tryParse('${value ?? ''}') ?? fallback;

  /// Loads the first page. The Notifications screen pages in more with
  /// [loadMore] as the user scrolls (the API returns at most 100 per page,
  /// so asking for "everything" silently dropped older notifications); the
  /// app-bar bell only needs the latest few ([pageSize] 20).
  Future<void> fetchNotifications({
    String search = '',
    String? audience,
    int pageSize = 50,
  }) async {
    final requestVersion = ++_requestVersion;
    _pageSize = pageSize;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _activeSearch = search.trim();
    final normalizedAudience = audience?.trim();
    _activeAudience = normalizedAudience == null || normalizedAudience.isEmpty
        ? null
        : normalizedAudience;
    notifyListeners();

    try {
      final response = await ApiClient.get(_pageUrl(1));
      final decodedData = jsonDecode(response.body);
      if (requestVersion != _requestVersion) return;

      if (decodedData['status'] == true && decodedData['data'] != null) {
        final res = AdminNotificationResponse.fromJson(decodedData);
        _notifications = res.data;
        _currentPage = _asInt(decodedData['page'], 1);
        _totalPages = _asInt(decodedData['total_pages'], 1);
      } else {
        _errorMessage =
            decodedData['message'] ?? "Failed to load notifications.";
      }
    } catch (e) {
      if (requestVersion == _requestVersion) {
        _errorMessage = "An error occurred: $e";
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Appends the next page (same search/audience filters).
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;
    final requestVersion = _requestVersion;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final response = await ApiClient.get(_pageUrl(_currentPage + 1));
      final decodedData = jsonDecode(response.body);
      if (requestVersion != _requestVersion) return;
      if (decodedData['status'] == true && decodedData['data'] != null) {
        final res = AdminNotificationResponse.fromJson(decodedData);
        final seen = _notifications.map((n) => n.id).toSet();
        _notifications = [
          ..._notifications,
          ...res.data.where((n) => !seen.contains(n.id)),
        ];
        _currentPage = _asInt(decodedData['page'], _currentPage + 1);
        _totalPages = _asInt(decodedData['total_pages'], _totalPages);
      }
    } catch (_) {
      // Keep what is already shown; scrolling again retries.
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true) {
        await fetchNotifications(
          search: _activeSearch,
          audience: _activeAudience,
        );
        return {
          'success': true,
          'message':
              decodedData['message'] ?? 'Notification created successfully',
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Failed to create notification',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<AdminNotification?> fetchNotificationDetails(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/$id/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true && decodedData['data'] != null) {
        return AdminNotification.fromJson(decodedData['data']);
      }
    } catch (e) {
      debugPrint("Error fetching notification details: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> updateNotification(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/$id/';
      final response = await ApiClient.patch(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true) {
        await fetchNotifications(
          search: _activeSearch,
          audience: _activeAudience,
        );
        return {
          'success': true,
          'message':
              decodedData['message'] ?? 'Notification updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Failed to update notification',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteNotification(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/$id/';
      final response = await ApiClient.delete(url);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true) {
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
        return {
          'success': true,
          'message':
              decodedData['message'] ?? 'Notification deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': decodedData['message'] ?? 'Failed to delete notification',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
