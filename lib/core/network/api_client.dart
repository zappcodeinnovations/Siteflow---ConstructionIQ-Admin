import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'api_endpoints.dart';
import '../services/auth_service.dart';
import '../../main.dart'; // To access the global navigatorKey

class ApiClient {
  static final http.Client _client = http.Client();
  static String? _deviceTimezone;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();
    
    try {
      _deviceTimezone ??= (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      debugPrint("[API Client] Error getting device timezone: $e");
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_deviceTimezone != null) 'X-Timezone': _deviceTimezone!,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static bool _isRefreshing = false;

  static Future<http.Response> _handleRequest(Future<http.Response> Function() requestAction) async {
    http.Response response = await requestAction();
    
    if (response.statusCode == 401 && !_isRefreshing) {
      debugPrint("[API Client] Received 401 Unauthorized for URL: ${response.request?.url}");
      _isRefreshing = true;
      try {
        final refreshToken = await AuthService.getRefreshToken();
        debugPrint("[API Client] Stored Refresh Token: ${refreshToken != null ? 'Found (length: ${refreshToken.length})' : 'Null/Empty'}");
        
        if (refreshToken != null && refreshToken.isNotEmpty) {
          debugPrint("[API Client] Attempting token refresh at: ${ApiEndpoints.baseUrl + ApiEndpoints.refresh}");
          final refreshResponse = await http.post(
            Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.refresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          );

          debugPrint("[API Client] Refresh Response Status: ${refreshResponse.statusCode}");
          debugPrint("[API Client] Refresh Response Body: ${refreshResponse.body}");

          if (refreshResponse.statusCode == 200) {
            final data = jsonDecode(refreshResponse.body);
            final newAccess = data['access'] ?? data['data']?['access'] ?? data['tokens']?['access'] ?? data['token'];
            final newRefresh = data['refresh'] ?? data['data']?['refresh'] ?? data['tokens']?['refresh'] ?? refreshToken;
            
            if (newAccess != null) {
              debugPrint("[API Client] Refresh successful! Saving new access token.");
              await AuthService.saveTokens(access: newAccess, refresh: newRefresh);
              _isRefreshing = false;
              return await requestAction();
            } else {
              debugPrint("[API Client] Refresh succeeded but new access token was null in payload.");
            }
          } else {
            debugPrint("[API Client] Refresh failed with status: ${refreshResponse.statusCode}");
          }
        } else {
          debugPrint("[API Client] No refresh token found. Skipping refresh flow.");
        }
        
        // If refresh fails or no refresh token exists, log out
        debugPrint("[API Client] Clearing stored tokens and redirecting to Login.");
        await AuthService.clearTokens();
        if (navigatorKey.currentState != null) {
          final context = navigatorKey.currentState!.context;
          String errorMsg = 'Session expired. Please login again.';
          
          try {
            final data = jsonDecode(response.body);
            if (data['detail'] != null) {
              errorMsg = data['detail'];
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );

          navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        debugPrint("[API Client] Exception caught during refresh flow: $e");
      } finally {
        _isRefreshing = false;
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
