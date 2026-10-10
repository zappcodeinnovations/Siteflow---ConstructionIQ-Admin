import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_support_model.dart';

class AdminSupportController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SupportQuickActions? _quickActions;
  SupportQuickActions? get quickActions => _quickActions;

  List<SupportTicket> _tickets = [];
  List<SupportTicket> get tickets => _tickets;

  SupportTicketDetails? _currentTicketDetails;
  SupportTicketDetails? get currentTicketDetails => _currentTicketDetails;

  Future<void> initializeData() async {
    await fetchQuickActions();
    await fetchTickets();
  }

  Future<void> fetchQuickActions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/support/quick-actions/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
           _quickActions = SupportQuickActions.fromJson(decoded['data']);
        }
      } else {
        _errorMessage = 'Failed to load support details.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(dynamic decoded, int statusCode) {
    if (decoded == null) return "Request failed with status $statusCode";
    if (decoded is String) {
      if (decoded.trim().isNotEmpty) return decoded.trim();
      return "Request failed with status $statusCode";
    }
    if (decoded is Map) {
      if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
        return decoded['message'].toString();
      }
      if (decoded['detail'] != null && decoded['detail'].toString().trim().isNotEmpty) {
        return decoded['detail'].toString();
      }
      if (decoded['error'] != null && decoded['error'].toString().trim().isNotEmpty) {
        return decoded['error'].toString();
      }
      if (decoded['non_field_errors'] != null) {
        final nfe = decoded['non_field_errors'];
        return nfe is List ? nfe.join(", ") : nfe.toString();
      }
      if (decoded['errors'] != null) {
        final errors = decoded['errors'];
        if (errors is Map) {
          return errors.entries.map((e) => "${e.key}: ${e.value}").join(", ");
        } else if (errors is List) {
          return errors.join(", ");
        }
        return errors.toString();
      }
      final fieldErrors = <String>[];
      decoded.forEach((key, value) {
        if (key != 'status' && key != 'code') {
          if (value is List) {
            fieldErrors.add("$key: ${value.join(', ')}");
          } else if (value is String && value.isNotEmpty) {
            fieldErrors.add("$key: $value");
          }
        }
      });
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join("\n");
      }
    }
    return "Failed to create support ticket (HTTP $statusCode).";
  }

  Future<Map<String, dynamic>> submitTicket({
    required String subject,
    required String category,
    required String priority,
    required String body,
    String? attachmentBase64,
    String? attachmentName,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final safeSubject = subject.trim().isNotEmpty
          ? subject.trim()
          : (body.trim().length > 50 ? "${body.trim().substring(0, 47)}..." : body.trim());

      final payload = <String, dynamic>{
        "subject": safeSubject,
        "title": safeSubject,
        "body": body.trim(),
        "message": body.trim(),
        "description": body.trim(),
        "category": category,
        "priority": priority,
        if (attachmentBase64 != null) "attachment": attachmentBase64,
        if (attachmentName != null) "attachment_name": attachmentName,
      };

      final endpoints = [
        '${ApiEndpoints.baseUrl}/admin/support/tickets/',
        '${ApiEndpoints.baseUrl}/support/tickets/',
        '${ApiEndpoints.baseUrl}/admin/support/',
        '${ApiEndpoints.baseUrl}/support/',
      ];

      dynamic lastDecoded;
      int lastStatusCode = 0;

      for (final url in endpoints) {
        try {
          final response = await ApiClient.post(url, body: payload);
          lastStatusCode = response.statusCode;
          try {
            lastDecoded = jsonDecode(response.body);
          } catch (_) {
            lastDecoded = response.body;
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (lastDecoded is Map && lastDecoded['status'] == false) {
              final msg = _extractErrorMessage(lastDecoded, response.statusCode);
              return {"success": false, "message": msg};
            }
            await fetchTickets(); // refresh list
            final successMsg = (lastDecoded is Map && lastDecoded['message'] != null)
                ? lastDecoded['message'].toString()
                : "Support ticket created successfully.";
            return {"success": true, "message": successMsg};
          } else if (response.statusCode != 404 && response.statusCode != 405) {
            final msg = _extractErrorMessage(lastDecoded, response.statusCode);
            return {"success": false, "message": msg};
          }
        } catch (e) {
          debugPrint("Failed submitting to $url: $e");
        }
      }

      final errorMsg = _extractErrorMessage(lastDecoded, lastStatusCode);
      return {"success": false, "message": errorMsg};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/support/tickets/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
           _tickets = (decoded['data'] as List).map((e) => SupportTicket.fromJson(e)).toList();
        }
      } else {
        _errorMessage = 'Failed to load tickets.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching tickets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTicketDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/support/tickets/$id/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
           _currentTicketDetails = SupportTicketDetails.fromJson(decoded['data']);
        }
      } else {
        _errorMessage = 'Failed to load ticket details.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred fetching ticket details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> replyToTicket(int id, String body) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/support/tickets/$id/reply/';
      final payload = {"body": body, "message": body};
      final response = await ApiClient.post(url, body: payload); 
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTicketDetails(id); // refresh messages
        return {"success": true, "message": "Reply sent."};
      }
      try {
        final decoded = jsonDecode(response.body);
        return {"success": false, "message": decoded['message'] ?? decoded['detail'] ?? "Failed to send reply."};
      } catch (_) {
        return {"success": false, "message": "Failed to send reply (${response.statusCode})."};
      }
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> reopenTicket(int id) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/support/tickets/$id/reopen/';
      final response = await ApiClient.post(url); 
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTicketDetails(id); // refresh status
        await fetchTickets(); // update list
        return {"success": true, "message": "Ticket reopened."};
      }
      return {"success": false, "message": "Failed to reopen ticket."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
