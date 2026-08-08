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

      var data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        // If response is not JSON, it might be a server error page (HTML)
      }

      if (response.statusCode == 200 && data != null && data['status'] == true) {
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
        if (response.statusCode == 401 || response.statusCode == 400 || response.statusCode == 404) {
          _errorMessage = (data != null && data['message'] != null) ? data['message'] : 'Invalid email or password.';
        } else {
          _errorMessage = (data != null && data['message'] != null) ? data['message'] : 'A server error occurred. Please try again.';
        }
        
        // Prevent showing long HTML or backend stack traces
        if (_errorMessage != null && (_errorMessage!.length > 100 || _errorMessage!.contains('<html'))) {
           _errorMessage = 'Invalid credentials or server error. Please try again.';
        }

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Unable to connect to the server. Please check your internet connection.';
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
