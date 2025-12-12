import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool success;
  final String? id;
  final String? email;
  final String? role;
  final String? error;

  AuthResult({
    required this.success,
    this.id,
    this.email,
    this.role,
    this.error,
  });
}

class LocalAuthService {
  static SupabaseClient get client => Supabase.instance.client;

  static Map<String, dynamic>? _sessionUser;

  static String? lastError;

  /// Registra un usuario usando RPC register_user (bcrypt hash en servidor)
  static Future<AuthResult> registerUser(String email, String password) async {
    lastError = null;
    try {
      final result = await client.rpc('register_user', params: {
        'p_email': email,
        'p_password': password,
      });

      if (result != null) {
        return AuthResult(
          success: true,
          id: result.toString(),
          email: email,
          role: 'user',
        );
      }
      lastError = 'Resultado vacío del servidor';
      return AuthResult(success: false, error: lastError);
    } catch (e) {
      lastError = e.toString();
      return AuthResult(success: false, error: lastError);
    }
  }

  /// Login usando RPC login_user (verifica bcrypt en servidor)
  static Future<AuthResult> loginUser(String email, String password) async {
    lastError = null;
    try {
      final result = await client.rpc('login_user', params: {
        'p_email': email,
        'p_password': password,
      });

      if (result != null && result is List && result.isNotEmpty) {
        _sessionUser = Map<String, dynamic>.from(result.first);
        return AuthResult(
          success: true,
          id: _sessionUser!['id']?.toString(),
          email: _sessionUser!['email']?.toString(),
          role: _sessionUser!['role']?.toString(),
        );
      }
      lastError = 'Credenciales incorrectas';
      return AuthResult(success: false, error: lastError);
    } catch (e) {
      lastError = e.toString();
      return AuthResult(success: false, error: lastError);
    }
  }

  static Map<String, dynamic>? get currentUser => _sessionUser;

  static String? get currentUserId => _sessionUser?['id']?.toString();

  static String? get currentUserEmail => _sessionUser?['email']?.toString();

  static String? get currentUserRole => _sessionUser?['role']?.toString();

  static bool get isLoggedIn => _sessionUser != null;

  static void logout() {
    _sessionUser = null;
  }
}
