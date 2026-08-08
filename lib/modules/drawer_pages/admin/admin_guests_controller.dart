import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_guest_model.dart';

class AdminGuestsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AdminGuest> _guests = [];
  List<AdminGuest> get guests => _guests;

  Future<void> fetchGuests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        final parsedResponse = AdminGuestResponse.fromJson(decodedData);
        _guests = parsedResponse.data;
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch guests';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> inviteGuest(Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/invite/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          await fetchGuests();
          return {"success": true, "message": decodedData['message'] ?? "Guest invited successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to invite guest."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<AdminGuest?> fetchGuestDetails(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        return AdminGuest.fromJson(decodedData['data']);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching guest details: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> updateGuest(int id, Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/';
      final response = await ApiClient.put(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchGuests();
          return {"success": true, "message": decodedData['message'] ?? "Guest updated successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to update guest."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteGuest(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/';
      final response = await ApiClient.delete(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchGuests();
          return {"success": true, "message": decodedData['message'] ?? "Guest deleted successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to delete guest."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
