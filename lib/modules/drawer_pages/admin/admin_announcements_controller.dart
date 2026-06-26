import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_notification_model.dart';

class AdminAnnouncementsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AdminNotification> _notifications = [];
  List<AdminNotification> get notifications => _notifications;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/notifications/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        final parsedResponse = AdminNotificationResponse.fromJson(decodedData);
        _notifications = parsedResponse.data;
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch notifications';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/notifications/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          await fetchNotifications();
          return {"success": true, "message": decodedData['message'] ?? "Notification created successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to create notification."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
