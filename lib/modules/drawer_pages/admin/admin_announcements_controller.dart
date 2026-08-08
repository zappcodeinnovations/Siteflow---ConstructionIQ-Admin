import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/announcement_model.dart';

class AdminAnnouncementsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Announcement> _announcements = [];
  List<Announcement> get announcements => _announcements;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/announcements/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        final parsedResponse = AnnouncementResponse.fromJson(decodedData);
        _announcements = parsedResponse.data;
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch announcements';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/announcements/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          await fetchAnnouncements();
          return {"success": true, "message": decodedData['message'] ?? "Announcement created successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to create announcement."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Announcement?> fetchAnnouncementDetails(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/announcements/$id/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        return Announcement.fromJson(decodedData['data']);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching announcement details: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/announcements/$id/';
      final response = await ApiClient.patch(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchAnnouncements();
          return {"success": true, "message": decodedData['message'] ?? "Announcement updated successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to update announcement."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteAnnouncement(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/announcements/$id/';
      final response = await ApiClient.delete(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchAnnouncements();
          return {"success": true, "message": decodedData['message'] ?? "Announcement deleted successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to delete announcement."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
