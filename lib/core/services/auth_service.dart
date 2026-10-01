import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_effective_role';
  static const String _userRoleLabelKey = 'user_role_label';
  static const String _permissionsKey = 'user_rbac_permissions';

  // Roles that get admin-only areas (e.g. "Admin Control"). Mirrors the
  // backend's own admin check (`_is_admin_api_user` in API/views.py):
  // superuser/admin roles, everything else (manager, operative, guest,
  // custom) is treated as a non-admin login.
  static const Set<String> _adminRoles = {'superuser', 'admin'};

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userRoleLabelKey);
    await prefs.remove(_permissionsKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Persist the role the backend returned for this login (`effective_role`
  /// / `role_label` on the user object), so the rest of the app can tell
  /// an admin/superuser login apart from a manager (or any other role)
  /// login without re-fetching the profile every time.
  static Future<void> saveUserRole({
    required String effectiveRole,
    String? roleLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, effectiveRole);
    await prefs.setString(_userRoleLabelKey, roleLabel ?? '');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<String?> getUserRoleLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString(_userRoleLabelKey);
    return (label == null || label.isEmpty) ? null : label;
  }

  /// True for admin/superuser logins; false for manager and every other
  /// role. Defaults to false (i.e. hides admin-only UI) if the role hasn't
  /// been saved yet.
  static Future<bool> isAdminUser() async {
    final role = await getUserRole();
    return role != null && _adminRoles.contains(role);
  }

  static Future<void> savePermissions(dynamic permissions) async {
    if (permissions is! Map) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_permissionsKey, jsonEncode(permissions));
  }

  static Future<Map<String, dynamic>> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_permissionsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Future<bool> can(String menuKey, {String action = 'view'}) async {
    if (await isAdminUser()) return true;
    final permissions = await getPermissions();
    final menu = permissions[menuKey];
    if (menu is Map) return menu[action] == true;

    // Compatibility for sessions created before the permissions API existed.
    final role = await getUserRole();
    if (role == 'manager') {
      return action == 'view' &&
          const {
            'dashboard',
            'projects',
            'tasks',
            'job_sheets',
            'daily_reports',
            'weekly_diary',
            'manager_diary',
            'approvals',
            'productivity',
            'workforce_planner',
            'timesheets',
            'manager_attendance',
          }.contains(menuKey);
    }
    return false;
  }
}
