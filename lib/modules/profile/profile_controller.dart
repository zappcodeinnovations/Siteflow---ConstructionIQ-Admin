iimport 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/user_model.dart';

class ProfileController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _profile;
  User? get profile => _profile;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.profile);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final payload = data['data'] ?? data;
        _profile = User.fromJson(payload['user'] ?? payload);
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch profile';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var response = await ApiClient.patch(
        ApiEndpoints.baseUrl + ApiEndpoints.profile,
        body: updateData,
      );

      // If PATCH is not allowed (405), fallback to PUT or POST
      if (response.statusCode == 405) {
        response = await ApiClient.put(
          ApiEndpoints.baseUrl + ApiEndpoints.profile,
          body: updateData,
        );
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {};
      }

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          (data is Map && (data['status'] == true || data['status'] == 'success' || data['user'] != null || data['data'] != null || data['id'] != null))) {
        final payload = data['data'] ?? data;
        final userMap = payload['user'] ?? payload;
        if (userMap is Map<String, dynamic> && userMap.containsKey('id')) {
          _profile = User.fromJson(userMap);
        } else {
          // Refresh profile data from server
          await fetchProfile();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            _errorMessage = data['message'].toString();
          } else if (data['detail'] != null) {
            _errorMessage = data['detail'].toString();
          } else if (data['error'] != null) {
            _errorMessage = data['error'].toString();
          } else if (data.isNotEmpty) {
            final firstVal = data.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              _errorMessage = firstVal.first.toString();
            } else {
              _errorMessage = firstVal.toString();
            }
          } else {
            _errorMessage = 'Failed to update profile (Status ${response.statusCode})';
          }
        } else {
          _errorMessage = 'Failed to update profile';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final payload = {
        'current_password': currentPassword,
        'old_password': currentPassword,
        'new_password': newPassword,
        'password': newPassword,
        'confirm_password': confirmPassword,
        'confirm_new_password': confirmPassword,
      };

      final endpoints = [
        '${ApiEndpoints.baseUrl}/profile/change-password/',
        '${ApiEndpoints.baseUrl}/auth/change-password/',
        '${ApiEndpoints.baseUrl}/admin/change-password/',
        '${ApiEndpoints.baseUrl}/change-password/',
      ];

      dynamic lastDecoded;
      for (final url in endpoints) {
        try {
          final response = await ApiClient.post(url, body: payload);
          try {
            lastDecoded = jsonDecode(response.body);
          } catch (_) {
            lastDecoded = response.body;
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (lastDecoded is Map && lastDecoded['status'] == false) {
              return {"success": false, "message": lastDecoded['message'] ?? "Failed to change password."};
            }
            return {"success": true, "message": (lastDecoded is Map && lastDecoded['message'] != null) ? lastDecoded['message'] : "Password updated successfully."};
          } else if (response.statusCode != 404 && response.statusCode != 405) {
            String errorMsg = "Failed to update password.";
            if (lastDecoded is Map) {
              errorMsg = lastDecoded['message'] ?? lastDecoded['detail'] ?? lastDecoded['error'] ?? errorMsg;
            }
            return {"success": false, "message": errorMsg};
          }
        } catch (_) {}
      }
      return {"success": false, "message": "Failed to update password. Please try again."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
