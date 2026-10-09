import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_permission_model.dart';

class AdminPermissionsController extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

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

  static const List<Map<String, String>> _fallbackMenuKeys = [
    {'key': 'dashboard', 'label': 'Dashboard'},
    {'key': 'clients', 'label': 'Clients'},
    {'key': 'projects', 'label': 'Projects'},
    {'key': 'tasks', 'label': 'Tasks'},
    {'key': 'job_sheets', 'label': 'Job Sheets'},
    {'key': 'daily_reports', 'label': 'Daily Reports'},
    {'key': 'weekly_diary', 'label': 'Weekly Diary'},
    {'key': 'productivity', 'label': 'Productivity'},
    {'key': 'timesheets', 'label': 'Timesheets'},
    {'key': 'manager_attendance', 'label': 'Authority Attendance'},
    {'key': 'library', 'label': 'Library'},
    {'key': 'notifications', 'label': 'Notifications'},
    {'key': 'settings', 'label': 'Settings'},
    {'key': 'admin', 'label': 'Admin'},
    {'key': 'settings/teams', 'label': 'Settings / Teams'},
  ];

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

    if (_menuKeys.isEmpty) {
      _menuKeys = _fallbackMenuKeys.map((item) {
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

  /// Rename/delete only apply to custom roles - [role.code] is the bare
  /// numeric CustomRole id (unlike [role.id], which is prefixed e.g.
  /// "custom:5"/"system:admin" to disambiguate built-in roles elsewhere).
  Future<Map<String, dynamic>> renameRole(AdminRole role, String newName) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/roles/${role.code}/';
      final response = await ApiClient.patch(url, body: {"name": newName});
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        await fetchRoles();
        return {"success": true, "message": decodedData['message'] ?? "Role renamed successfully."};
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to rename role."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteRole(AdminRole role) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/admin/permissions/roles/${role.code}/';
      final response = await ApiClient.delete(url);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == true) {
        if (_selectedRole?.id == role.id) {
          _selectedRole = null;
        }
        await fetchRoles();
        return {"success": true, "message": decodedData['message'] ?? "Role deleted successfully."};
      }
      return {"success": false, "message": decodedData['message'] ?? "Failed to delete role."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    }
  }

  bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final lower = val.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  String _formatLabel(String key) {
    if (key.isEmpty) return '';
    return key
        .replaceAll('_', ' ')
        .replaceAll('/', ' / ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  Future<void> fetchPermissions(AdminRole role) async {
    _isLoading = true;
    _errorMessage = null;
    
    if (_menuKeys.isEmpty) {
      _menuKeys = _fallbackMenuKeys.map((item) {
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
          final permsData = decodedData['data'];
          Map<String, dynamic> permsMap = {};
          if (permsData is Map<String, dynamic>) {
            if (permsData['permissions'] is Map<String, dynamic>) {
              permsMap = permsData['permissions'] as Map<String, dynamic>;
            } else {
              permsMap = permsData;
            }
          } else if (decodedData['permissions'] is Map<String, dynamic>) {
            permsMap = decodedData['permissions'] as Map<String, dynamic>;
          }

          dynamic getPermEntry(String key) {
            if (permsMap.containsKey(key)) return permsMap[key];
            final altKey1 = key.replaceAll('_', '/');
            if (permsMap.containsKey(altKey1)) return permsMap[altKey1];
            final altKey2 = key.replaceAll('/', '_');
            if (permsMap.containsKey(altKey2)) return permsMap[altKey2];
            
            for (var entry in permsMap.entries) {
              if (entry.key.toLowerCase().replaceAll('_', '').replaceAll('/', '') ==
                  key.toLowerCase().replaceAll('_', '').replaceAll('/', '')) {
                return entry.value;
              }
            }
            return null;
          }
           
          for (int i = 0; i < _permissions.length; i++) {
            final key = _permissions[i].menuKey;
            final item = getPermEntry(key);
            if (item != null && item is Map) {
              _permissions[i].canView = _parseBool(item['view']);
              _permissions[i].canCreate = _parseBool(item['create']);
              _permissions[i].canEdit = _parseBool(item['edit']);
              _permissions[i].canDelete = _parseBool(item['delete']);
            }
          }

          for (var entry in permsMap.entries) {
            final key = entry.key;
            if (entry.value is! Map) continue;
            final item = entry.value as Map;
            final alreadyExists = _permissions.any((p) =>
                p.menuKey.toLowerCase().replaceAll('_', '').replaceAll('/', '') ==
                key.toLowerCase().replaceAll('_', '').replaceAll('/', ''));
            if (!alreadyExists) {
              _permissions.add(PermissionItem(
                menuKey: key,
                label: _formatLabel(key),
                canView: _parseBool(item['view']),
                canCreate: _parseBool(item['create']),
                canEdit: _parseBool(item['edit']),
                canDelete: _parseBool(item['delete']),
              ));
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
      case 'view':
        item.canView = value;
        break;
      case 'create':
        item.canCreate = value;
        if (value) item.canView = true;
        break;
      case 'edit':
        item.canEdit = value;
        if (value) item.canView = true;
        break;
      case 'delete':
        item.canDelete = value;
        if (value) item.canView = true;
        break;
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
