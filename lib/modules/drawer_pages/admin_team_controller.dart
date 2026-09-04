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
