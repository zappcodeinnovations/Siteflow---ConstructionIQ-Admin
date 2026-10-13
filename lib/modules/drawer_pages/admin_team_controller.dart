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
    String? nickname,
    String? leadId,
    List<int>? projectIds,
    String? shiftStartTime,
    String? shiftEndTime,
    String? shiftTimezone,
  }) async {
    _isSaving = true;
    // Note: do NOT notifyListeners() here — fetchTeams() handles its own
    // notifications internally (start + end). An extra notify here causes
    // the SettingsScreen to rebuild twice after the dialog dismisses,
    // which produces the visual "screen stack" regression.

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/teams/';
      final response = await ApiClient.post(url, body: {
        if (shiftTimezone != null && shiftTimezone.isNotEmpty) "shift_timezone": shiftTimezone,
        "name": name,
        if (nickname != null && nickname.isNotEmpty) "nickname": nickname,
        if (leadId != null && leadId.isNotEmpty) "lead_id": leadId,
        if (projectIds != null && projectIds.isNotEmpty) "project_ids": projectIds,
        if (shiftStartTime != null && shiftStartTime.isNotEmpty)
          "shift_start_time": shiftStartTime,
        if (shiftEndTime != null && shiftEndTime.isNotEmpty)
          "shift_end_time": shiftEndTime,
      });

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchTeams(); // fetchTeams() calls notifyListeners() internally
        return {
          "success": true,
          "message": decoded['message'] ?? 'Team created successfully.',
        };
      }
      // fetchTeams not called on failure — notify once to clear saving state
      _isSaving = false;
      notifyListeners();
      return {
        "success": false,
        "message": decoded['message'] ?? 'Failed to create team.',
      };
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>?> fetchTeamDetail(int teamId) async {
    try {
      // Fire all 3 requests in parallel for fast loading
      final results = await Future.wait([
        ApiClient.get('${ApiEndpoints.baseUrl}/admin/teams/$teamId/'),
        ApiClient.get(
          '${ApiEndpoints.baseUrl}/admin/members/?role=operative&status=active&page_size=1000',
        ),
        ApiClient.get('${ApiEndpoints.baseUrl}/projects/?page_size=1000'),
        ApiClient.get(
          '${ApiEndpoints.baseUrl}/admin/members/?role=manager&status=active&page_size=1000',
        ),
      ]);

      final teamResp = results[0];
      final operativesResp = results[1];
      final projectsResp = results[2];
      final managersResp = results[3];

      if (teamResp.statusCode != 200) return null;

      final teamDecoded = jsonDecode(teamResp.body);
      final teamData =
          (teamDecoded['data'] as Map?)?.cast<String, dynamic>() ?? {};

      // Parse all operatives → used for member picker AND team lead choices
      final allOperatives = <Map<String, dynamic>>[];
      if (operativesResp.statusCode == 200) {
        final dec = jsonDecode(operativesResp.body);
        final raw = dec is List
            ? dec
            : (dec['data'] is List ? dec['data'] : dec['results']);
        if (raw is List) {
          for (final m in raw) {
            if (m is Map) {
              allOperatives.add({
                'id': m['id'],
                'name':
                    m['display_name'] ?? m['name'] ?? m['full_name'] ?? m['email'] ?? '',
                'employee_id': m['email'] ?? m['employee_id'] ?? '',
              });
            }
          }
        }
      }

      // Parse managers for team lead choices (managers + supervisors)
      final allManagers = <Map<String, dynamic>>[];
      if (managersResp.statusCode == 200) {
        final dec = jsonDecode(managersResp.body);
        final raw = dec is List
            ? dec
            : (dec['data'] is List ? dec['data'] : dec['results']);
        if (raw is List) {
          for (final m in raw) {
            if (m is Map) {
              allManagers.add({
                'id': m['id'],
                'name':
                    m['display_name'] ?? m['name'] ?? m['full_name'] ?? m['email'] ?? '',
              });
            }
          }
        }
      }

      // Parse all projects
      final allProjects = <Map<String, dynamic>>[];
      if (projectsResp.statusCode == 200) {
        final dec = jsonDecode(projectsResp.body);
        final raw = dec is List
            ? dec
            : (dec['data'] is List
                ? dec['data']
                : dec['results'] is List
                    ? dec['results']
                    : null);
        if (raw is List) {
          for (final p in raw) {
            if (p is Map) {
              allProjects.add({
                'id': p['id'],
                'name': p['name'] ?? p['display_name'] ?? '',
              });
            }
          }
        }
      }

      // Determine already-assigned member IDs so we can separate them
      final assignedIds = <int>{};
      final assignedRaw =
          (teamData['assigned_members'] as List?) ?? [];
      for (final m in assignedRaw) {
        if (m is Map && m['id'] != null) {
          assignedIds.add(m['id'] as int);
        }
      }

      // available_members = all operatives NOT already in this team
      final availableMembers = allOperatives
          .where((m) => !assignedIds.contains(m['id']))
          .toList();

      // team_lead_choices = managers + supervisors (broader set for lead)
      // Merge managers with operatives, dedupe by id
      final leadMap = <int, Map<String, dynamic>>{};
      for (final m in [...allManagers, ...allOperatives]) {
        final id = m['id'];
        if (id is int) leadMap[id] = m;
      }
      final teamLeadChoices = leadMap.values.toList()
        ..sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String));

      // Merge everything into one map the screen can read
      return {
        ...teamData,
        'all_projects': allProjects,
        'available_members': availableMembers,
        'team_lead_choices': teamLeadChoices,
      };
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
