import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_notification_model.dart';

class AdminNotificationsController extends ChangeNotifier {
  List<AdminNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true && decodedData['data'] != null) {
        final res = AdminNotificationResponse.fromJson(decodedData);
        _notifications = res.data;
      } else {
        _errorMessage = decodedData['message'] ?? "Failed to load notifications.";
      }
    } catch (e) {
      _errorMessage = "An error occurred: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true) {
        await fetchNotifications();
        return {'success': true, 'message': decodedData['message'] ?? 'Notification created successfully'};
      } else {
        return {'success': false, 'message': decodedData['message'] ?? 'Failed to create notification'};
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

  Future<Map<String, dynamic>> updateNotification(int id, Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/notifications/$id/';
      final response = await ApiClient.patch(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (decodedData['status'] == true) {
        await fetchNotifications();
        return {'success': true, 'message': decodedData['message'] ?? 'Notification updated successfully'};
      } else {
        return {'success': false, 'message': decodedData['message'] ?? 'Failed to update notification'};
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
        return {'success': true, 'message': decodedData['message'] ?? 'Notification deleted successfully'};
      } else {
        return {'success': false, 'message': decodedData['message'] ?? 'Failed to delete notification'};
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
