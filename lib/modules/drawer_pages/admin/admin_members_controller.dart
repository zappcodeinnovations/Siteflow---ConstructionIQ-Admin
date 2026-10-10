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

  int? _totalCount;
  int get totalCount => _totalCount ?? _members.length;

  int? _assignedCount;
  int? get assignedCount => _assignedCount;

  int? _invitedCount;
  int? get invitedCount => _invitedCount;

  String _statusFilter = 'active';
  String get statusFilter => _statusFilter;

  String _roleFilter = 'all';
  String get roleFilter => _roleFilter;

  Future<void> fetchMembers({String? status, String? role, String? search}) async {
    if (status != null) _statusFilter = status;
    if (role != null) _roleFilter = role;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String>['page_size=1000'];
      if (_statusFilter.isNotEmpty && _statusFilter != 'all') {
        queryParams.add('status=$_statusFilter');
      }
      if (_roleFilter.isNotEmpty && _roleFilter != 'all') {
        queryParams.add('role=$_roleFilter');
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }

      final url = '${ApiEndpoints.baseUrl}/admin/members/?${queryParams.join('&')}';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && (decodedData['status'] == true || decodedData is List || decodedData.containsKey('data'))) {
        final parsedResponse = AdminMemberResponse.fromJson(decodedData);
        _members = parsedResponse.data;
        _totalCount = parsedResponse.totalCount ?? _members.length;
        if (parsedResponse.assignedCount != null) {
          _assignedCount = parsedResponse.assignedCount;
        }
        if (parsedResponse.invitedCount != null) {
          _invitedCount = parsedResponse.invitedCount;
        }
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

  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    fetchMembers();
  }

  void setRoleFilter(String role) {
    if (_roleFilter == role) return;
    _roleFilter = role;
    fetchMembers();
  }

  Future<Map<String, dynamic>> resendInvite(int id, {String? email}) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/members/$id/resend-invite/';
      final response = await ApiClient.post(url, body: {
        if (email != null && email.isNotEmpty) "email": email,
      });
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": decodedData['message'] ?? "Invitation resent successfully."};
      }

      // Fallback endpoint
      final fallbackUrl = '${ApiEndpoints.baseUrl}/admin/members/invite/resend/';
      final fallbackRes = await ApiClient.post(fallbackUrl, body: {
        "member_id": id,
        if (email != null && email.isNotEmpty) "email": email,
      });
      final fallbackDecoded = jsonDecode(fallbackRes.body);

      if (fallbackRes.statusCode == 200 || fallbackRes.statusCode == 201) {
        return {"success": true, "message": fallbackDecoded['message'] ?? "Invitation resent successfully."};
      }

      return {"success": false, "message": decodedData['message'] ?? fallbackDecoded['message'] ?? "Failed to resend invite."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
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

  Future<Map<String, dynamic>> updateMember(int id, Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/members/$id/';
      final response = await ApiClient.patch(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        await fetchMembers();
        return {"success": true, "message": decodedData['message'] ?? "Member updated successfully."};
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to update member."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<AdminMember?> fetchMemberDetails(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/members/$id/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        return AdminMember.fromJson(decodedData['data']);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching member details: $e");
      return null;
    }
  }
}
