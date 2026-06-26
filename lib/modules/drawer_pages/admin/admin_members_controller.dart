import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_member_model.dart';

class AdminMembersController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AdminMember> _members = [];
  List<AdminMember> get members => _members;

  Future<void> fetchMembers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/members/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        final parsedResponse = AdminMemberResponse.fromJson(decodedData);
        _members = parsedResponse.data;
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch members';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> inviteMember(Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/members/invite/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          await fetchMembers();
          return {"success": true, "message": decodedData['message'] ?? "Invite sent successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to invite member."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteMember(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/members/$id/';
      final response = await ApiClient.delete(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchMembers();
          return {"success": true, "message": decodedData['message'] ?? "Member deleted successfully."};
        }
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to delete member."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
