import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/models/user_app.dart';
import 'package:marketmove_app/services/session_service.dart';

class UsersService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Get all users - only accessible by admin and superadmin
  static Future<List<UserApp>> getAllUsers() async {
    final isAdmin = await SessionService.isAdmin();
    if (!isAdmin) return [];

    final response = await _client
        .from('users_app')
        .select('id, email, role, created_at')
        .order('created_at', ascending: false);

    return (response as List).map((e) => UserApp.fromJson(e)).toList();
  }

  /// Get a single user by ID - only accessible by admin and superadmin
  static Future<UserApp?> getUser(String id) async {
    final isAdmin = await SessionService.isAdmin();
    if (!isAdmin) return null;

    final response = await _client
        .from('users_app')
        .select('id, email, role, created_at')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return UserApp.fromJson(response);
  }

  /// Update user role - only accessible by superadmin
  static Future<bool> updateUserRole(String userId, String newRole) async {
    final isSuperAdmin = await SessionService.isSuperAdmin();
    if (!isSuperAdmin) return false;

    // Validate role
    if (newRole != 'user' && newRole != 'admin' && newRole != 'superadmin') {
      return false;
    }

    // Prevent changing own role
    final currentUserId = await SessionService.getUserId();
    if (currentUserId == userId) return false;

    await _client
        .from('users_app')
        .update({'role': newRole})
        .eq('id', userId);

    return true;
  }

  /// Delete user - only accessible by superadmin
  static Future<bool> deleteUser(String userId) async {
    final isSuperAdmin = await SessionService.isSuperAdmin();
    if (!isSuperAdmin) return false;

    // Prevent deleting self
    final currentUserId = await SessionService.getUserId();
    if (currentUserId == userId) return false;

    // Delete user's data first (cascade)
    await _client.from('productos').delete().eq('user_id', userId);
    await _client.from('ventas').delete().eq('user_id', userId);
    await _client.from('gastos').delete().eq('user_id', userId);
    
    // Delete the user
    await _client.from('users_app').delete().eq('id', userId);

    return true;
  }

  /// Get user count by role - only accessible by admin and superadmin
  static Future<Map<String, int>> getUserCountByRole() async {
    final isAdmin = await SessionService.isAdmin();
    if (!isAdmin) return {};

    final response = await _client
        .from('users_app')
        .select('role');

    Map<String, int> counts = {'user': 0, 'admin': 0, 'superadmin': 0};
    for (var row in response as List) {
      final role = row['role'] as String? ?? 'user';
      counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  }
}
