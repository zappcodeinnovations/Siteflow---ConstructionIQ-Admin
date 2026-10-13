import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../models/admin_guest_model.dart';

class AdminGuestsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AdminGuest> _guests = [];
  List<AdminGuest> get guests => _guests;

  int? _activeCount;
  int get activeCount => _activeCount ?? 0;

  int? _invitedCount;
  int get invitedCount => _invitedCount ?? 0;

  String _statusFilter = 'active';
  String get statusFilter => _statusFilter;

  Future<void> fetchGuests({String? status, String? search}) async {
    if (status != null) _statusFilter = status;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String>[
        'page_size=1000',
        'status=${Uri.encodeQueryComponent(_statusFilter)}',
      ];
      if (search != null && search.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }
      final url =
          '${ApiEndpoints.baseUrl}/admin/guests/?${queryParams.join('&')}';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        final parsedResponse = AdminGuestResponse.fromJson(decodedData);
        _guests = parsedResponse.data;
        _activeCount = parsedResponse.activeCount;
        _invitedCount = parsedResponse.invitedCount;
      } else {
        _errorMessage = decodedData['message'] ?? 'Failed to fetch guests';
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
    _guests = [];
    _errorMessage = null;
    notifyListeners();
    fetchGuests();
  }

  Future<Map<String, dynamic>> inviteGuest(Map<String, dynamic> payload) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/invite/';
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decodedData['status'] == true) {
          await fetchGuests();
          return {
            "success": true,
            "message": decodedData['message'] ?? "Guest invited successfully.",
          };
        }
      }
      return {
        "success": false,
        "message": decodedData['message'] ?? "Failed to invite guest.",
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<AdminGuest?> fetchGuestDetails(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/';
      final response = await ApiClient.get(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        return AdminGuest.fromJson(decodedData['data']);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching guest details: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> updateGuest(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/';
      final response = await ApiClient.put(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchGuests();
          return {
            "success": true,
            "message": decodedData['message'] ?? "Guest updated successfully.",
          };
        }
      }
      return {
        "success": false,
        "message": decodedData['message'] ?? "Failed to update guest.",
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> convertToMember(
    int id, {
    String role = 'operative',
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/convert-to-member/';
      final response = await ApiClient.post(url, body: {"role": role});
      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200 && decodedData['status'] == true) {
        await fetchGuests();
        return {
          "success": true,
          "message": decodedData['message'] ?? "Converted to member.",
        };
      }
      return {
        "success": false,
        "message": decodedData['message'] ?? "Failed to convert guest.",
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteGuest(int id) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/$id/';
      final response = await ApiClient.delete(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decodedData['status'] == true) {
          await fetchGuests();
          return {
            "success": true,
            "message": decodedData['message'] ?? "Guest deleted successfully.",
          };
        }
      }
      return {
        "success": false,
        "message": decodedData['message'] ?? "Failed to delete guest.",
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<bool> downloadImportTemplate() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/import-template/';
      final result = await DownloadManager.instance.downloadUrl(
        url: url,
        fileName: 'guest-import-template.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      return result != null;
    } catch (e) {
      debugPrint("Error downloading guest import template: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> importGuestsExcel(String filePath) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/guests/import/';
      final response = await ApiClient.postMultipart(
        url,
        filePath: filePath,
        fileFieldName: "xlsx_file",
      );
      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200 && decodedData['status'] == true) {
        await fetchGuests();
        return {
          "success": true,
          "message": decodedData['message'] ?? 'Import complete.',
          "data": decodedData['data'],
        };
      }
      return {
        "success": false,
        "message": decodedData['message'] ?? 'Failed to import guests.',
      };
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
