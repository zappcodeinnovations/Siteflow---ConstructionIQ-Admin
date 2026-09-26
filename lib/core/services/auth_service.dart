import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_effective_role';
  static const String _userRoleLabelKey = 'user_role_label';

  // Roles that get admin-only areas (e.g. "Admin Control"). Mirrors the
  // backend's own admin check (`_is_admin_api_user` in API/views.py):
  // superuser/admin roles, everything else (manager, operative, guest,
  // custom) is treated as a non-admin login.
  static const Set<String> _adminRoles = {'superuser', 'admin'};

  static Future<void> saveTokens({required String access, required String refresh}) async {
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
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Persist the role the backend returned for this login (`effective_role`
  /// / `role_label` on the user object), so the rest of the app can tell
  /// an admin/superuser login apart from a manager (or any other role)
  /// login without re-fetching the profile every time.
  static Future<void> saveUserRole({required String effectiveRole, String? roleLabel}) async {
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
}
