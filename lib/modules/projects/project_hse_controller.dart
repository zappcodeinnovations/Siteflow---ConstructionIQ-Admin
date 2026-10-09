import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/hse_document_model.dart';

class ProjectHseController extends ChangeNotifier {
  final int projectId;
  ProjectHseController(this.projectId);

  bool isLoading = false;
  bool isActionLoading = false;
  String? error;
  List<HseDocumentModel> documents = [];
  List<HseDocumentModel> recycleBinDocuments = [];
  int unacknowledgedWorkersCount = 0;

  String get _baseUrl => ApiEndpoints.baseUrl + ApiEndpoints.projectHseDocuments(projectId);

  Future<void> fetchDocuments() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final response = await ApiClient.get(_baseUrl);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List || decoded.containsKey('data'))) {
        final list = (decoded['data'] ?? decoded['results'] ?? (decoded is List ? decoded : [])) as List? ?? [];
        documents = list
            .whereType<Map>()
            .map((e) => HseDocumentModel.fromJson(e.cast<String, dynamic>()))
            .toList();

        unacknowledgedWorkersCount = decoded['unacknowledged_workers_count'] ??
            decoded['unacknowledged_count'] ??
            decoded['pending_signatures_count'] ??
            0;
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch HS&E documents.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument({
    required String category,
    required String title,
    required String filePath,
    String? expiryDate,
    String? notes,
    bool requireSign = false,
  }) async {
    isActionLoading = true;
    notifyListeners();
    try {
      final fields = {
        'category': category,
        'title': title,
        if (expiryDate != null && expiryDate.isNotEmpty) 'expiry_date': expiryDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'requires_acknowledgment': requireSign ? 'true' : 'false',
        'require_sign': requireSign ? 'true' : 'false',
      };

      final response = await ApiClient.postMultipart(
        _baseUrl,
        filePath: filePath,
        fileFieldName: 'file',
        fields: fields,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDocuments();
        return true;
      }
    } catch (e) {
      debugPrint("Error uploading HS&E document: $e");
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> reviseDocument({
    required int docId,
    required String category,
    required String title,
    required String filePath,
    String? expiryDate,
    String? notes,
  }) async {
    isActionLoading = true;
    notifyListeners();
    try {
      final fields = {
        'category': category,
        'title': title,
        if (expiryDate != null && expiryDate.isNotEmpty) 'expiry_date': expiryDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'revision': 'true',
        'document_id': docId.toString(),
      };

      // Try revision endpoint or primary endpoint with doc id
      var response = await ApiClient.postMultipart(
        '$_baseUrl$docId/revise/',
        filePath: filePath,
        fileFieldName: 'file',
        fields: fields,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        response = await ApiClient.postMultipart(
          _baseUrl,
          filePath: filePath,
          fileFieldName: 'file',
          fields: fields,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDocuments();
        return true;
      }
    } catch (e) {
      debugPrint("Error revising HS&E document: $e");
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteDocument(int docId) async {
    isActionLoading = true;
    notifyListeners();
    try {
      var response = await ApiClient.delete('$_baseUrl$docId/');
      if (response.statusCode != 200 && response.statusCode != 204) {
        response = await ApiClient.delete('$_baseUrl?document_id=$docId');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchDocuments();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting HS&E document: $e");
    } finally {
      isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchRecycleBin() async {
    try {
      final url = '$_baseUrl?recycle_bin=true';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List || decoded.containsKey('data'))) {
        final list = (decoded['data'] ?? decoded['results'] ?? (decoded is List ? decoded : [])) as List? ?? [];
        recycleBinDocuments = list
            .whereType<Map>()
            .map((e) => HseDocumentModel.fromJson(e.cast<String, dynamic>()))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching recycle bin: $e");
    }
  }

  Future<bool> restoreDocument(int docId) async {
    try {
      final response = await ApiClient.post('$_baseUrl$docId/restore/', body: {});
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchDocuments();
        await fetchRecycleBin();
        return true;
      }
    } catch (e) {
      debugPrint("Error restoring document: $e");
    }
    return false;
  }
}
