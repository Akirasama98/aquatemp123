import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../supabase_config.dart';

class AuthController {
  static final _client = SupabaseConfig.client;
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  // Initialize - Check if user is already logged in
  static Future<void> initialize() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    }
  }

  // Sign up with email and password
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user != null) {
        // Create user profile in our custom table
        await _createUserProfile(response.user!, name, phone);
        await _loadUserProfile(response.user!.id);
        return AuthResult.success('Registrasi berhasil! Silahkan cek email untuk verifikasi.');
      } else {
        return AuthResult.error('Gagal mendaftar. Silahkan coba lagi.');
      }
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // Sign in with email and password
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return AuthResult.success('Login berhasil!');
      } else {
        return AuthResult.error('Gagal login. Silahkan coba lagi.');
      }
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // Sign out
  static Future<AuthResult> signOut() async {
    try {
      await _client.auth.signOut();
      _currentUser = null;
      return AuthResult.success('Logout berhasil!');
    } catch (e) {
      return AuthResult.error('Gagal logout: ${e.toString()}');
    }
  }

  // Update user profile
  static Future<AuthResult> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.error('User tidak ditemukan');
      }

      await _client.from('profiles').update({
        'name': name,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUser!.id);

      await _loadUserProfile(_currentUser!.id);
      return AuthResult.success('Profile berhasil diupdate!');
    } catch (e) {
      return AuthResult.error('Gagal update profile: ${e.toString()}');
    }
  }

  // Load user profile from database
  static Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromJson(response);
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Create user profile in database
  static Future<void> _createUserProfile(User user, String? name, String? phone) async {
    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'name': name,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // Get error message from AuthException
  static String _getErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email atau password salah';
      case 'Email not confirmed':
        return 'Email belum diverifikasi. Silahkan cek email Anda.';
      case 'Password should be at least 6 characters':
        return 'Password minimal 6 karakter';
      case 'Unable to validate email address: invalid format':
        return 'Format email tidak valid';
      case 'User already registered':
        return 'Email sudah terdaftar';
      default:
        return e.message;
    }
  }

  // Reset password
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return AuthResult.success('Link reset password telah dikirim ke email Anda');
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan: ${e.toString()}');
    }
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult.success(this.message) : success = true;
  AuthResult.error(this.message) : success = false;
}
