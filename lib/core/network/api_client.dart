import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';
import '../utils/date_helper.dart';
import '../../main.dart'; // To access the global navigatorKey

class ApiClient {
  static final http.Client _client = http.Client();
  static String? _deviceTimezone;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();
    
    try {
      _deviceTimezone ??= await DateHelper.getDeviceTimezone();
    } catch (e) {
      AppLogger.w("Error getting device timezone: $e", tag: "API Client");
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
      AppLogger.w("Received 401 Unauthorized for URL: ${response.request?.url}", tag: "API Client");
      _isRefreshing = true;
      try {
        final refreshToken = await AuthService.getRefreshToken();
        AppLogger.i("Stored Refresh Token: ${refreshToken != null ? 'Found (length: ${refreshToken.length})' : 'Null/Empty'}", tag: "API Client");
        
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshUrl = ApiEndpoints.baseUrl + ApiEndpoints.refresh;
          AppLogger.i("Attempting token refresh at: $refreshUrl", tag: "API Client");
          final refreshResponse = await http.post(
            Uri.parse(refreshUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          );

          AppLogger.i("Refresh Response Status: ${refreshResponse.statusCode}", tag: "API Client");

          if (refreshResponse.statusCode == 200) {
            final data = jsonDecode(refreshResponse.body);
            final newAccess = data['access'] ?? data['data']?['access'] ?? data['tokens']?['access'] ?? data['token'];
            final newRefresh = data['refresh'] ?? data['data']?['refresh'] ?? data['tokens']?['refresh'] ?? refreshToken;
            
            if (newAccess != null) {
              AppLogger.i("Refresh successful! Saving new access token.", tag: "API Client");
              await AuthService.saveTokens(access: newAccess, refresh: newRefresh);
              _isRefreshing = false;
              return await requestAction();
            } else {
              AppLogger.w("Refresh succeeded but new access token was null in payload.", tag: "API Client");
            }
          } else {
            AppLogger.w("Refresh failed with status: ${refreshResponse.statusCode}", tag: "API Client");
          }
        } else {
          AppLogger.w("No refresh token found. Skipping refresh flow.", tag: "API Client");
        }
        
        // If refresh fails or no refresh token exists, log out
        AppLogger.w("Clearing stored tokens and redirecting to Login.", tag: "API Client");
        await AuthService.clearTokens();
        if (navigatorKey.currentState != null) {
          final context = navigatorKey.currentState!.context;
          const String userFriendlyErrorMsg = 'Your session has expired. Please log in again to continue.';

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                userFriendlyErrorMsg,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );

          navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e, stack) {
        AppLogger.e("Exception caught during refresh flow", error: e, stackTrace: stack, tag: "API Client");
      } finally {
        _isRefreshing = false;
      }
    }
    
    return response;
  }

  static Future<http.Response> _executeWithLogging({
    required String method,
    required String url,
    dynamic body,
    required Future<http.Response> Function(Map<String, String> headers) requestAction,
  }) async {
    final headers = await _getHeaders();
    AppLogger.request(method, url, headers: headers, body: body);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _handleRequest(() => requestAction(headers));
      stopwatch.stop();
      AppLogger.response(
        method,
        url,
        response.statusCode,
        body: response.body,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      return response;
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.networkError(
        method,
        url,
        e,
        stackTrace: stack,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  static Future<http.Response> get(String url) async {
    return _executeWithLogging(
      method: 'GET',
      url: url,
      requestAction: (headers) => _client.get(Uri.parse(url), headers: headers),
    );
  }

  static Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return _executeWithLogging(
      method: 'POST',
      url: url,
      body: body,
      requestAction: (headers) => _client.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  static Future<http.Response> delete(String url) async {
    return _executeWithLogging(
      method: 'DELETE',
      url: url,
      requestAction: (headers) => _client.delete(Uri.parse(url), headers: headers),
    );
  }

  static Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    return _executeWithLogging(
      method: 'PUT',
      url: url,
      body: body,
      requestAction: (headers) => _client.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  /// Multipart POST for file uploads - [fields] become form fields,
  /// [filePath] is sent under [fileFieldName] ("file" by default, matching
  /// every admin/project file-upload endpoint on the backend).
  static Future<http.Response> postMultipart(
    String url, {
    required String filePath,
    String fileFieldName = 'file',
    Map<String, String>? fields,
  }) async {
    final stopwatch = Stopwatch()..start();
    final headers = await _getHeaders();
    headers.remove('Content-Type'); // let MultipartRequest set its own boundary

    AppLogger.request('POST (MULTIPART)', url, headers: headers, body: {
      'fileFieldName': fileFieldName,
      'filePath': filePath,
      if (fields != null) 'fields': fields,
    });

    try {
      final response = await _handleRequest(() async {
        final request = http.MultipartRequest('POST', Uri.parse(url))
          ..headers.addAll(headers)
          ..fields.addAll(fields ?? {})
          ..files.add(await http.MultipartFile.fromPath(fileFieldName, filePath));
        final streamedResponse = await request.send();
        return await http.Response.fromStream(streamedResponse);
      });

      stopwatch.stop();
      AppLogger.response(
        'POST (MULTIPART)',
        url,
        response.statusCode,
        body: response.body,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      return response;
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.networkError(
        'POST (MULTIPART)',
        url,
        e,
        stackTrace: stack,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    }
  }

  static Future<http.Response> patch(String url, {Map<String, dynamic>? body}) async {
    return _executeWithLogging(
      method: 'PATCH',
      url: url,
      body: body,
      requestAction: (headers) => _client.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }
}
