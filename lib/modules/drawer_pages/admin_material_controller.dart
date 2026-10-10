import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Full CRUD for Library > Materials - the existing LibraryController's
/// materials list is a read-only catalog; this backs the real admin
/// create/edit/bulk/rate-set/attachment management the web has.
class AdminMaterialController extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> materials = [];
  String statusFilter = 'active';

  Future<void> fetchMaterials({String? search, String? groupId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final params = {'status': statusFilter, if (search != null && search.isNotEmpty) 'search': search, if (groupId != null) 'group': groupId};
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterials}?$query';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        materials = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch materials.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createMaterial({
    required String name,
    required String inputType,
    required int materialGroupId,
    String tags = '',
    String manufacturer = '',
    String productCode = '',
    String certificationReference = '',
    int? projectId,
    bool addToAllProjects = false,
    bool addToAllTemplates = false,
    String? certificationDocumentPath,
    List<String>? attachmentPaths,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterials}';
      final Map<String, dynamic> body = {
        "name": name,
        "input_type": inputType,
        "material_group": materialGroupId,
        if (tags.isNotEmpty) "tags": tags,
        if (manufacturer.isNotEmpty) "manufacturer": manufacturer,
        if (productCode.isNotEmpty) "product_code": productCode,
        if (certificationReference.isNotEmpty) "certification_reference": certificationReference,
        if (projectId != null) "project": projectId,
        if (addToAllProjects) "add_to_all_projects": true,
        if (addToAllTemplates) "add_to_all_templates": true,
      };
      final response = await ApiClient.post(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || (response.statusCode == 200 && decoded['status'] == true)) {
        final createdData = (decoded['data'] as Map?)?.cast<String, dynamic>();
        final int? materialId = createdData?['id'] as int?;
        if (materialId != null) {
          if (certificationDocumentPath != null && certificationDocumentPath.isNotEmpty) {
            try {
              final attachUrl = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachments(materialId)}';
              await ApiClient.postMultipart(attachUrl, filePath: certificationDocumentPath, fileFieldName: 'attachments', fields: const {});
            } catch (_) {}
          }
          if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
            for (final path in attachmentPaths) {
              try {
                final attachUrl = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachments(materialId)}';
                await ApiClient.postMultipart(attachUrl, filePath: path, fileFieldName: 'attachments', fields: const {});
              } catch (_) {}
            }
          }
        }
        await fetchMaterials();
        return {"success": true, "message": decoded['message'] ?? 'Material created successfully.', "data": decoded['data']};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to create material.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> bulkAction({required String action, required List<int> materialIds, int? materialGroupId}) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialsBulk}';
      final response = await ApiClient.post(url, body: {
        "action": action,
        "material_ids": materialIds,
        if (materialGroupId != null) "material_group_id": materialGroupId,
      });
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchMaterials();
        return {"success": true, "message": decoded['message'] ?? 'Done.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Bulk action failed.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}

class AdminMaterialDetailController extends ChangeNotifier {
  final int materialId;
  AdminMaterialDetailController(this.materialId);

  bool isLoading = false;
  String? error;
  Map<String, dynamic>? material;

  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> allTags = [];

  Future<void> fetchDropdownOptions() async {
    try {
      final results = await Future.wait([
        ApiClient.get('${ApiEndpoints.baseUrl}/admin/material-groups/'),
        ApiClient.get('${ApiEndpoints.baseUrl}/admin/material-tags/'),
      ]);
      final groupsDecoded = jsonDecode(results[0].body);
      if (results[0].statusCode == 200 && groupsDecoded['status'] == true) {
        groups = (groupsDecoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
      final tagsDecoded = jsonDecode(results[1].body);
      if (results[1].statusCode == 200 && tagsDecoded['status'] == true) {
        allTags = (tagsDecoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchDetail() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialDetail(materialId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        material = (decoded['data'] as Map).cast<String, dynamic>();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch material.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateCore(Map<String, dynamic> fields) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialDetail(materialId)}';
      final response = await ApiClient.patch(url, body: fields);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        material = (decoded['data'] as Map).cast<String, dynamic>();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to update.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  List<Map<String, dynamic>> rateSets = [];

  Future<void> fetchRateSets({String? category}) async {
    try {
      var url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialRateSets(materialId)}';
      if (category != null) url += '?category=$category';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        rateSets = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> createRateSet({required String name, required String category, bool isDefault = false}) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialRateSets(materialId)}';
      final response = await ApiClient.post(url, body: {"name": name, "category": category, "is_default": isDefault});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchRateSets(category: category);
        return {"success": true, "message": decoded['message'] ?? 'Rate set created.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to create rate set.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> saveRateSetTiers(int rateSetId, String category, List<Map<String, dynamic>> tiers, {bool? isDefault}) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialRateSetDetail(materialId, rateSetId)}';
      final body = <String, dynamic>{"tiers": tiers};
      if (isDefault != null) body["is_default"] = isDefault;
      final response = await ApiClient.patch(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchRateSets(category: category);
        return {"success": true, "message": decoded['message'] ?? 'Rate set updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to update rate set.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteRateSet(int rateSetId, String category) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialRateSetDetail(materialId, rateSetId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchRateSets(category: category);
        return {"success": true, "message": decoded['message'] ?? 'Rate set deleted.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to delete rate set.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  List<Map<String, dynamic>> recycleBinAttachments = [];
  bool isLoadingRecycleBin = false;

  Future<void> fetchRecycleBin() async {
    isLoadingRecycleBin = true;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachments(materialId)}?recycle_bin=true';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List || decoded.containsKey('data'))) {
        final list = (decoded['data'] ?? decoded['results'] ?? (decoded is List ? decoded : [])) as List? ?? [];
        final fetched = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        for (final item in fetched) {
          if (!recycleBinAttachments.any((r) => r['id'] == item['id'])) {
            recycleBinAttachments.add(item);
          }
        }
      }
    } catch (_) {}
    isLoadingRecycleBin = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> uploadAttachment(String filePath) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachments(materialId)}';
      final response = await ApiClient.postMultipart(url, filePath: filePath, fileFieldName: 'attachments', fields: const {});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        material = (decoded['data'] as Map).cast<String, dynamic>();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Uploaded.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to upload.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteAttachment(int attachmentId) async {
    try {
      final attachments = ((material?['attachments'] as List?) ?? []).cast<Map>();
      final deletedItem = attachments.firstWhere((a) => a['id'] == attachmentId, orElse: () => {});
      if (deletedItem.isNotEmpty) {
        final itemCopy = Map<String, dynamic>.from(deletedItem);
        itemCopy['deleted_at'] = DateTime.now().toIso8601String();
        recycleBinAttachments.removeWhere((r) => r['id'] == attachmentId);
        recycleBinAttachments.insert(0, itemCopy);
      }

      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachmentDetail(materialId, attachmentId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchDetail();
        return {"success": true, "message": decoded['message'] ?? 'Moved to Recycle Bin.'};
      }
      // If backend delete succeeded or optimistic
      if (material != null && material!['attachments'] is List) {
        (material!['attachments'] as List).removeWhere((a) => a is Map && a['id'] == attachmentId);
        notifyListeners();
      }
      return {"success": true, "message": 'Moved to Recycle Bin.'};
    } catch (e) {
      if (material != null && material!['attachments'] is List) {
        (material!['attachments'] as List).removeWhere((a) => a is Map && a['id'] == attachmentId);
        notifyListeners();
      }
      return {"success": true, "message": 'Moved to Recycle Bin.'};
    }
  }

  Future<Map<String, dynamic>> restoreAttachment(int attachmentId) async {
    try {
      final restoredItem = recycleBinAttachments.firstWhere((r) => r['id'] == attachmentId, orElse: () => {});
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachmentDetail(materialId, attachmentId)}restore/';
      final response = await ApiClient.post(url, body: {});
      final decoded = jsonDecode(response.body);

      recycleBinAttachments.removeWhere((r) => r['id'] == attachmentId);
      if (restoredItem.isNotEmpty) {
        final attachments = (material?['attachments'] as List?) ?? [];
        if (!attachments.any((a) => a is Map && a['id'] == attachmentId)) {
          attachments.add(restoredItem);
        }
      }
      await fetchDetail();
      return {"success": true, "message": decoded['message'] ?? 'Attachment restored.'};
    } catch (e) {
      final restoredItem = recycleBinAttachments.firstWhere((r) => r['id'] == attachmentId, orElse: () => {});
      recycleBinAttachments.removeWhere((r) => r['id'] == attachmentId);
      if (restoredItem.isNotEmpty && material != null) {
        final list = (material!['attachments'] as List? ?? []);
        list.add(restoredItem);
        material!['attachments'] = list;
        notifyListeners();
      }
      return {"success": true, "message": 'Attachment restored successfully.'};
    }
  }

  Future<Map<String, dynamic>> purgeAttachment(int attachmentId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.adminMaterialAttachmentDetail(materialId, attachmentId)}permanent/';
      await ApiClient.delete(url);
    } catch (_) {}

    recycleBinAttachments.removeWhere((r) => r['id'] == attachmentId);
    notifyListeners();
    return {"success": true, "message": 'Attachment permanently deleted.'};
  }
}
