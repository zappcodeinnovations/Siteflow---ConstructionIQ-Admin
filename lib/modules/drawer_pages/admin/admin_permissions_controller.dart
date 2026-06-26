import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_permission_model.dart';

class AdminPermissionsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AdminRole> _roles = [];
  List<AdminRole> get roles => _roles;

  AdminRole? _selectedRole;
  AdminRole? get selectedRole => _selectedRole;

  List<PermissionItem> _permissions = [];
  List<PermissionItem> get permissions => _permissions;

  List<String> _menuKeys = [];

  Future<void> initializeData() async {
    await fetchRoles();
    await fetchMenuKeys();
  }

  Future<void> fetchRoles() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/permissions/roles/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        dynamic decodedData = jsonDecode(response.body);
        List<dynamic> rolesList = [];
        
        if (decodedData is List) {
          rolesList = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          rolesList = decodedData['data'];
        }

        _roles = rolesList.map((i) => AdminRole.fromJson(i)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching roles: $e");
    }
  }

  Future<void> fetchMenuKeys() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/permissions/menu-keys/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
           _menuKeys = decodedData.map((e) => e.toString()).toList();
        } else if (decodedData is Map && decodedData.containsKey('data')) {
           _menuKeys = (decodedData['data'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      print("Error fetching menu keys: $e");
    }
    
    if (_menuKeys.isEmpty) {
      _menuKeys = [
        "dashboard", "clients", "projects", "tasks", "job_sheets",
        "productivity", "timesheets", "authority_attendance", "library"
      ];
    }
  }

  Future<Map<String, dynamic>> createRole(String name, String description) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/permissions/roles/';
      final payload = {"name": name, "description": description};
      
      final response = await ApiClient.post(url, body: payload);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRoles();
        return {"success": true, "message": decodedData['message'] ?? "Role created successfully."};
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to create role."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  void selectRole(AdminRole role) {
    _selectedRole = role;
    notifyListeners();
    fetchPermissions(role);
  }

  Future<void> fetchPermissions(AdminRole role) async {
    _isLoading = true;
    _errorMessage = null;
    _permissions = [];
    notifyListeners();

    try {
      final roleFormat = role.isSystem ? 'system:${role.name.toLowerCase()}' : 'custom:${role.id}';
      final url = '${ApiEndpoints.baseUrl}/api/admin/permissions/roles/$roleFormat/permissions/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        dynamic responseData;
        try {
           responseData = jsonDecode(response.body);
        } catch (_) {
           responseData = {};
        }

        Map<String, dynamic> permsMap = {};
        if (responseData is Map) {
          if (responseData.containsKey('permissions')) {
            permsMap = Map<String, dynamic>.from(responseData['permissions'] ?? {});
          } else {
            permsMap = Map<String, dynamic>.from(responseData);
          }
        }

        _permissions = _menuKeys.map((key) {
           if (permsMap.containsKey(key)) {
             return PermissionItem.fromJson(key, permsMap[key]);
           } else {
             return PermissionItem(menuKey: key, canView: false, canCreate: false, canEdit: false, canDelete: false);
           }
        }).toList();

      } else {
        _errorMessage = 'Failed to fetch permissions.';
        _initializeDefaultPermissions();
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _initializeDefaultPermissions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeDefaultPermissions() {
    _permissions = _menuKeys.map((key) => PermissionItem(
      menuKey: key, canView: false, canCreate: false, canEdit: false, canDelete: false
    )).toList();
  }

  void updatePermission(int index, String field, bool value) {
    if (index < 0 || index >= _permissions.length) return;
    final item = _permissions[index];
    switch (field) {
      case 'view': item.canView = value; break;
      case 'create': item.canCreate = value; break;
      case 'edit': item.canEdit = value; break;
      case 'delete': item.canDelete = value; break;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> savePermissions() async {
    if (_selectedRole == null) return {"success": false, "message": "No role selected"};

    _isSaving = true;
    notifyListeners();

    try {
      final roleFormat = _selectedRole!.isSystem ? 'system:${_selectedRole!.name.toLowerCase()}' : 'custom:${_selectedRole!.id}';
      final url = '${ApiEndpoints.baseUrl}/api/admin/permissions/roles/$roleFormat/permissions/';
      
      Map<String, dynamic> permissionsMap = {};
      for (var p in _permissions) {
        permissionsMap[p.menuKey] = p.toJsonValue();
      }

      final payload = {"permissions": permissionsMap};
      final response = await ApiClient.post(url, body: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": "Permissions saved successfully."};
      }
      return {"success": false, "message": "Failed to save permissions."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
