import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/admin_team_model.dart';

class AdminTeamController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AdminTeam> _teams = [];
  List<AdminTeam> get teams => _teams;

  Future<void> fetchTeams() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/';
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map ? decoded['data'] : null) as List?;
        _teams = list
                ?.whereType<Map>()
                .map((e) => AdminTeam.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            [];
      } else {
        _errorMessage = 'Failed to load teams.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createTeam({
    required String name,
    String? shiftStartTime,
    String? shiftEndTime,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/';
      final response = await ApiClient.post(url, body: {
        "name": name,
        if (shiftStartTime != null && shiftStartTime.isNotEmpty)
          "shift_start_time": shiftStartTime,
        if (shiftEndTime != null && shiftEndTime.isNotEmpty)
          "shift_end_time": shiftEndTime,
      });

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchTeams();
        return {
          "success": true,
          "message": decoded['message'] ?? 'Team created successfully.',
        };
      }
      return {
        "success": false,
        "message": decoded['message'] ?? 'Failed to create team.',
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchTeamDetail(int teamId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/$teamId/';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return (decoded['data'] as Map?)?.cast<String, dynamic>();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching team detail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateTeam(int teamId, Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/$teamId/';
      final response = await ApiClient.patch(url, body: payload);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchTeams();
        return {"success": true, "message": decoded['message'] ?? 'Team updated.', "data": decoded['data']};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to update team.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteTeam(int teamId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/$teamId/';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchTeams();
        return {"success": true, "message": decoded['message'] ?? 'Team deleted.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to delete team.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> assignMembers(int teamId, List<int> memberIds) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/$teamId/members/';
      final response = await ApiClient.post(url, body: {"member_ids": memberIds});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded['message'] ?? 'Members added.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to add members.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> removeMember(int teamId, int memberId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/$teamId/members/$memberId/';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded['message'] ?? 'Member removed.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to remove member.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> forceClockOut(int teamId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/$teamId/force-clock-out/';
      final response = await ApiClient.post(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": decoded['message'] ?? 'Done.',
        };
      }
      return {
        "success": false,
        "message": decoded['message'] ?? 'Failed to force clock out.',
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
