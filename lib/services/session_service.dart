import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Role constants
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  static const String roleSuperAdmin = 'superadmin';

  static Future<void> saveSession({
    required String userId,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('email', email);
    await prefs.setString('role', role);
    await prefs.setBool('logged_in', true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('logged_in') ?? false;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  /// Returns true if the current user is a superadmin
  static Future<bool> isSuperAdmin() async {
    final role = await getRole();
    return role == roleSuperAdmin;
  }

  /// Returns true if the current user is an admin OR superadmin
  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == roleAdmin || role == roleSuperAdmin;
  }

  /// Returns true if the current user is a regular user (not admin/superadmin)
  static Future<bool> isUser() async {
    final role = await getRole();
    return role == roleUser;
  }

  /// Get the global view preference (superadmin only)
  static Future<bool> getGlobalViewEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('global_view_enabled') ?? true;
  }

  /// Set the global view preference (superadmin only)
  static Future<void> setGlobalViewEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_view_enabled', enabled);
  }

  /// Check if should use global view (superadmin with global view enabled)
  static Future<bool> shouldUseGlobalView() async {
    final isSuperAdmin = await SessionService.isSuperAdmin();
    if (!isSuperAdmin) return false;
    return await getGlobalViewEnabled();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
