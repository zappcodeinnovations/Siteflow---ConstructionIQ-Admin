import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/project_issue_models.dart';

/// Backs the Incidents, Snags, and Inspections project tabs - all three
/// share the same {status, message, data} response shape and the same
/// list+report workflow, so one controller covers all three instead of
/// duplicating the same fetch/create plumbing three times.
class ProjectIssuesController extends ChangeNotifier {
  final int projectId;
  ProjectIssuesController(this.projectId);

  bool isLoadingIncidents = false;
  bool isLoadingSnags = false;
  bool isLoadingInspections = false;

  String? incidentsError;
  String? snagsError;
  String? inspectionsError;

  List<IncidentModel> incidents = [];
  List<SnagModel> snags = [];
  List<InspectionModel> inspections = [];

  Future<void> fetchIncidents() async {
    isLoadingIncidents = true;
    incidentsError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectIncidents(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        incidents = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => IncidentModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        incidentsError = decoded['message']?.toString() ?? 'Failed to fetch incidents.';
      }
    } catch (e) {
      incidentsError = 'An error occurred: $e';
    } finally {
      isLoadingIncidents = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> reportIncident(Map<String, dynamic> payload) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectIncidents(projectId);
      final response = await ApiClient.post(url, body: payload);
      final decoded = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && decoded['status'] == true) {
        await fetchIncidents();
        return {'success': true, 'message': decoded['message'] ?? 'Incident reported.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to report incident.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<void> fetchSnags() async {
    isLoadingSnags = true;
    snagsError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectSnags(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        snags = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => SnagModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        snagsError = decoded['message']?.toString() ?? 'Failed to fetch snags.';
      }
    } catch (e) {
      snagsError = 'An error occurred: $e';
    } finally {
      isLoadingSnags = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> raiseSnag(Map<String, dynamic> payload) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectSnags(projectId);
      final response = await ApiClient.post(url, body: payload);
      final decoded = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && decoded['status'] == true) {
        await fetchSnags();
        return {'success': true, 'message': decoded['message'] ?? 'Snag raised.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to raise snag.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSnag(int snagId) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectSnagDetail(projectId, snagId);
      var response = await ApiClient.delete(url);
      if (response.statusCode != 200 && response.statusCode != 204) {
        final fallbackUrl = ApiEndpoints.baseUrl + ApiEndpoints.snagDetail(snagId);
        response = await ApiClient.delete(fallbackUrl);
      }
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 204 || decoded['status'] == true) {
        await fetchSnags();
        return {'success': true, 'message': decoded['message'] ?? 'Snag deleted successfully.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to delete snag.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSnagStatus(int snagId, String newStatus) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectSnagDetail(projectId, snagId);
      var response = await ApiClient.patch(url, body: {'status': newStatus});
      if (response.statusCode != 200) {
        final fallbackUrl = ApiEndpoints.baseUrl + ApiEndpoints.snagDetail(snagId);
        response = await ApiClient.patch(fallbackUrl, body: {'status': newStatus});
      }
      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || decoded['status'] == true) {
        await fetchSnags();
        return {'success': true, 'message': decoded['message'] ?? 'Snag status updated.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to update snag status.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<void> fetchInspections() async {
    isLoadingInspections = true;
    inspectionsError = null;
    notifyListeners();
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectInspections(projectId);
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        inspections = (decoded['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => InspectionModel.fromJson(e.cast<String, dynamic>()))
            .toList();
      } else {
        inspectionsError = decoded['message']?.toString() ?? 'Failed to fetch inspections.';
      }
    } catch (e) {
      inspectionsError = 'An error occurred: $e';
    } finally {
      isLoadingInspections = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> logInspection(Map<String, dynamic> payload) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.projectInspections(projectId);
      final response = await ApiClient.post(url, body: payload);
      final decoded = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && decoded['status'] == true) {
        await fetchInspections();
        return {'success': true, 'message': decoded['message'] ?? 'Inspection logged.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to log inspection.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> completeInspection(int inspectionId, Map<String, dynamic> payload) async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.inspectionComplete(inspectionId);
      final response = await ApiClient.post(url, body: payload);
      final decoded = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && decoded['status'] == true) {
        await fetchInspections();
        return {'success': true, 'message': decoded['message'] ?? 'Inspection completed.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Failed to complete inspection.'};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
