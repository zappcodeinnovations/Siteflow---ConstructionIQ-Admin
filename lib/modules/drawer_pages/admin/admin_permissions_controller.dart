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

  List<PermissionItem> _menuKeys = [];
  List<PermissionItem> get menuKeys => _menuKeys;

  Future<void> initializeData() async {
    await fetchMenuKeys();
    await fetchRoles();
  }

  Future<void> fetchMenuKeys() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/menu-keys/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['status'] == true && decodedData['data'] != null) {
          final keysList = decodedData['data'] as List;
          _menuKeys = keysList.map((item) {
             return PermissionItem(
               menuKey: item['key'] ?? '',
               label: item['label'] ?? '',
               canView: false,
               canCreate: false,
               canEdit: false,
               canDelete: false,
             );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching menu keys: $e");
    }
  }

  Future<void> fetchRoles() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/roles/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        dynamic decodedData = jsonDecode(response.body);
        
        if (decodedData['status'] == true && decodedData['data'] != null) {
          final rolesList = decodedData['data'] as List;
          _roles = rolesList.map((i) => AdminRole.fromJson(i)).toList();
          
          if (_roles.isNotEmpty && _selectedRole == null) {
            // Automatically select the first role by default
            selectRole(_roles.first);
          } else {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching roles: $e");
    }
  }

  Future<Map<String, dynamic>> createRole(String name, String description) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/roles/';
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
    
    // Initialize permissions from menu keys to show all options as false by default
    _permissions = _menuKeys.map((k) => PermissionItem(
       menuKey: k.menuKey,
       label: k.label,
       canView: false,
       canCreate: false,
       canEdit: false,
       canDelete: false,
    )).toList();
    
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/roles/${role.id}/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        
        if (decodedData['status'] == true && decodedData['data'] != null) {
           final permsMap = decodedData['data'] as Map<String, dynamic>;
           
           for (int i = 0; i < _permissions.length; i++) {
             final key = _permissions[i].menuKey;
             if (permsMap.containsKey(key)) {
               final item = permsMap[key];
               _permissions[i].canView = item['view'] ?? false;
               _permissions[i].canCreate = item['create'] ?? false;
               _permissions[i].canEdit = item['edit'] ?? false;
               _permissions[i].canDelete = item['delete'] ?? false;
             }
           }
        }
      } else {
        _errorMessage = 'Failed to fetch permissions.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/roles/${_selectedRole!.id}/';
      
      Map<String, dynamic> permissionsMap = {};
      for (var p in _permissions) {
        permissionsMap[p.menuKey] = p.toJsonValue();
      }

      final payload = permissionsMap; 
      final response = await ApiClient.patch(url, body: payload);
      final decodedData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": decodedData['message'] ?? "Permissions updated successfully."};
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to save permissions."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
