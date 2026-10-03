import 'dart:convert';
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
      final response = await ApiClient.patch(
        ApiEndpoints.baseUrl + ApiEndpoints.profile,
        body: updateData,
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      final isSuccess = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (data == null ||
              data['status'] == null ||
              data['status'] == true ||
              data['status'] == 'success');

      if (isSuccess) {
        if (data is Map<String, dynamic>) {
          final payload = data['data'] ?? data;
          final userJson = payload is Map<String, dynamic>
              ? (payload['user'] ?? (payload['id'] != null ? payload : null))
              : null;
          if (userJson is Map<String, dynamic>) {
            _profile = User.fromJson(userJson);
          }
        }
        // Refresh full profile data to ensure all UI components are synchronized
        await fetchProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = (data is Map && data['message'] != null)
            ? data['message']
            : (data is Map && data['detail'] != null)
                ? data['detail']
                : 'Failed to update profile (HTTP ${response.statusCode})';
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
}
