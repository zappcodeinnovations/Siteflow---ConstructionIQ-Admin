import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_model.dart';

class LoginController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Check if payload is wrapped in 'data'
        final payload = data['data'] ?? data;

        // Save tokens
        final tokens = payload['tokens'];
        await AuthService.saveTokens(
          access: tokens['access'],
          refresh: tokens['refresh'],
        );

        // Parse user
        _currentUser = User.fromJson(payload['user']);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login failed: ${response.body}';
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

  Future<void> logout() async {
    await AuthService.clearTokens();
    _currentUser = null;
    notifyListeners();
  }
}
