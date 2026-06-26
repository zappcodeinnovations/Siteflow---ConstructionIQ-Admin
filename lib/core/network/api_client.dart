import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../../main.dart'; // To access the global navigatorKey

class ApiClient {
  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _handleRequest(Future<http.Response> Function() requestAction) async {
    http.Response response = await requestAction();
    
    if (response.statusCode == 401) {
      // The token is invalid/expired and there is no refresh API
      await AuthService.clearTokens();
      
      // Kick the user back to the login screen immediately
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
    
    return response;
  }

  static Future<http.Response> get(String url) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return await _client.get(Uri.parse(url), headers: headers);
    });
  }

  static Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> delete(String url) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return await _client.delete(Uri.parse(url), headers: headers);
    });
  }

  static Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return await _client.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    return _handleRequest(() async {
      final headers = await _getHeaders();
      return await _client.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }
}
