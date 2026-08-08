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

  Future<Map<String, dynamic>> submitTicket({
    required String subject,
    required String category,
    required String priority,
    required String body,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/support/tickets/';
      final payload = {
        "subject": subject,
        "body": body,
        "category": category,
        "priority": priority,
      };

      final response = await ApiClient.post(url, body: payload); 
      final decoded = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTickets(); // refresh list
        return {"success": true, "message": decoded['message'] ?? "Support ticket created successfully."};
      }
      return {"success": false, "message": decoded['message'] ?? "Failed to create support ticket."};
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
      final payload = {"body": body};
      final response = await ApiClient.post(url, body: payload); 
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTicketDetails(id); // refresh messages
        return {"success": true, "message": "Reply sent."};
      }
      return {"success": false, "message": "Failed to send reply."};
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
