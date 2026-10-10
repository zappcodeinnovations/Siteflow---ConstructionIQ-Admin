import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class SpecificationController extends ChangeNotifier {
  final int projectId;
  SpecificationController(this.projectId);

  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> specifications = [];

  Future<void> fetchSpecifications({String? search}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      var url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecifications(projectId)}';
      if (search != null && search.isNotEmpty) url += '?q=${Uri.encodeQueryComponent(search)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        specifications = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch specifications.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createSpecification(String name, String code) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecifications(projectId)}';
      final response = await ApiClient.post(url, body: {"name": name, "code": code});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchSpecifications();
        return {"success": true, "message": decoded['message'] ?? 'Added.', "data": decoded['data']};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to create specification.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  // Project-level attribute DEFINITIONS (shared schema across every
  // specification on this project), backing the "Manage Attributes"
  // toolbar action - distinct from a single specification's attribute
  // VALUES, which live on SpecificationDetailController.
  bool isLoadingAttributeDefinitions = false;
  List<Map<String, dynamic>> attributeDefinitions = [];

  Future<void> fetchAttributeDefinitions() async {
    isLoadingAttributeDefinitions = true;
    notifyListeners();
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributeDefinitions(projectId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final data = (decoded['data'] as Map).cast<String, dynamic>();
        attributeDefinitions = (data['definitions'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {
    } finally {
      isLoadingAttributeDefinitions = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createAttributeDefinition({
    required String name,
    required String attributeType,
    List<String> options = const [],
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributeDefinitions(projectId)}';
      final response = await ApiClient.post(url, body: {"name": name, "attribute_type": attributeType, "options": options});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await fetchAttributeDefinitions();
        return {"success": true, "message": decoded['message'] ?? 'Added.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to add attribute.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteAttributeDefinition(int definitionId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributeDefinitionDetail(projectId, definitionId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchAttributeDefinitions();
        return {"success": true, "message": decoded['message'] ?? 'Removed.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to remove attribute.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteSpecification(int specId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationDetail(projectId, specId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await fetchSpecifications();
        return {"success": true, "message": decoded['message'] ?? 'Deleted.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to delete specification.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}

class SpecificationDetailController extends ChangeNotifier {
  final int projectId;
  final int specId;
  SpecificationDetailController(this.projectId, this.specId);

  bool isLoading = false;
  String? error;
  Map<String, dynamic>? spec;
  List<Map<String, dynamic>> attributeDefinitions = [];
  List<Map<String, dynamic>> availableMaterials = [];

  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([_fetchSpec(), _fetchDefinitions(), _fetchAvailableMaterials()]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSpec() async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationDetail(projectId, specId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        spec = (decoded['data'] as Map).cast<String, dynamic>();
      } else {
        error = decoded['message']?.toString() ?? 'Failed to fetch specification.';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    }
  }

  Future<void> _fetchDefinitions() async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributeDefinitions(projectId)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final data = (decoded['data'] as Map).cast<String, dynamic>();
        attributeDefinitions = (data['definitions'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchAvailableMaterials() async {
    try {
      final url = ApiEndpoints.baseUrl + ApiEndpoints.libraryMaterials;
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        availableMaterials = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> updateCore({String? name, String? code, String? price}) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationDetail(projectId, specId)}';
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (price != null) body['price'] = price;
      final response = await ApiClient.patch(url, body: body);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to update.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> saveAttributeValues(Map<String, dynamic> values) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributes(projectId, specId)}';
      final response = await ApiClient.patch(url, body: {"values": values});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        spec = (decoded['data'] as Map).cast<String, dynamic>();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Attributes saved.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to save attributes.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> createAttributeDefinition({
    required String name,
    required String attributeType,
    List<String> options = const [],
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributeDefinitions(projectId)}';
      final response = await ApiClient.post(url, body: {"name": name, "attribute_type": attributeType, "options": options});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _fetchDefinitions();
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Added.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to add attribute.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteAttributeDefinition(int definitionId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationAttributeDefinitionDetail(projectId, definitionId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _fetchDefinitions();
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Removed.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to remove attribute.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> addMaterial(int materialId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationMaterials(projectId, specId)}';
      final response = await ApiClient.post(url, body: {"material_id": materialId});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Added.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to add material.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> removeMaterial(int materialId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationMaterialDetail(projectId, specId, materialId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Removed.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to remove material.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> addPriceItem({required String name, required String quantity, required String unitPrice}) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationPriceItems(projectId, specId)}';
      final response = await ApiClient.post(url, body: {"name": name, "quantity": quantity, "unit_price": unitPrice});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Added.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to add item.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> updatePriceItem({
    required int itemId,
    required String name,
    required String quantity,
    required String unitPrice,
  }) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationPriceItemDetail(projectId, specId, itemId)}';
      final response = await ApiClient.patch(url, body: {"name": name, "quantity": quantity, "unit_price": unitPrice});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Updated.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to update item.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deletePriceItem(int itemId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationPriceItemDetail(projectId, specId, itemId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Removed.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to remove item.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, String title) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationFiles(projectId, specId)}';
      final response = await ApiClient.postMultipart(url, filePath: filePath, fields: {"title": title});
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Uploaded.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to upload file.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteFile(int fileId) async {
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.projectSpecificationFileDetail(projectId, specId, fileId)}';
      final response = await ApiClient.delete(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _fetchSpec();
        notifyListeners();
        return {"success": true, "message": decoded['message'] ?? 'Removed.'};
      }
      return {"success": false, "message": decoded['message'] ?? 'Failed to remove file.'};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }
}
