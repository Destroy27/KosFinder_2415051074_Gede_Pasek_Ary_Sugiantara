import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_keys.dart';
import '../pages/login_page.dart';
import 'profile_service.dart';

/// Satu pintu untuk seluruh operasi autentikasi Supabase.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentSession != null;

  /// Mendengarkan perubahan session, misalnya ketika token dicabut atau
  /// pengguna logout dari perangkat lain.
  void listenAuthChanges() {
    _client.auth.onAuthStateChange.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedOut) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          _loginRoute(),
          (route) => false,
        );
      }
    });
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'name': name, 'role': role},
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Mengambil role pengguna yang sedang login.
  Future<UserProfile?> currentProfile() => _profileService.getMyProfile();

  static Route<void> _loginRoute() {
    return MaterialPageRoute<void>(
      builder: (_) => const LoginPage(),
      settings: const RouteSettings(name: '/login'),
    );
  }
}
