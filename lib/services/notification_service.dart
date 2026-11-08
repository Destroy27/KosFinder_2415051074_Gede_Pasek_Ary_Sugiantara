import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Handler untuk pesan yang diterima saat aplikasi di background atau
/// terminated. Wajib berupa fungsi top-level dan memakai `vm:entry-point`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Konfigurasi Firebase belum tersedia; cukup lanjut mencatat pesan.
  }
  debugPrint('[BACKGROUND] title: ${message.notification?.title}');
  debugPrint('[BACKGROUND] body : ${message.notification?.body}');
  debugPrint('[BACKGROUND] data : ${message.data}');
}

/// Status dan operasi seputar notifikasi FCM.
///
/// Kelas ini turunan [ChangeNotifier] agar status permission dan token bisa
/// ditampilkan langsung pada halaman profil.
class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool _started = false;
  String _permission = 'belum diminta';
  String? _token;
  String? _error;

  String get permission => _permission;
  String? get token => _token;
  String? get error => _error;

  /// FCM hanya didukung pada Android dan iOS.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_started) return;
    _started = true;
    if (!isSupported) {
      _permission = 'tidak didukung di platform ini';
      notifyListeners();
      return;
    }

    try {
      await requestPermission();
      await getToken();
      listenTokenRefresh();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<String> requestPermission() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _permission = settings.authorizationStatus.name;
      _error = null;
    } catch (error) {
      _permission = 'gagal meminta izin';
      _error = error.toString();
    }
    notifyListeners();
    return _permission;
  }

  Future<String?> getToken() async {
    try {
      final String? token = await _messaging.getToken();
      _token = token;
      _error = null;
      if (token != null) {
        await saveTokenToSupabase(token);
      }
    } catch (error) {
      _error = error.toString();
    }
    notifyListeners();
    return _token;
  }

  /// Token dapat berubah, misalnya setelah aplikasi di-install ulang.
  void listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((String newToken) {
      _token = newToken;
      notifyListeners();
      saveTokenToSupabase(newToken);
    });
  }

  /// Mendaftarkan perangkat ke tabel `device_tokens`.
  ///
  /// Token tidak pernah ditulis di source code dan tidak di-commit ke Git.
  Future<void> saveTokenToSupabase(String token) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null || !SupabaseConfig.isConfigured) return;

    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        <String, dynamic>{
          'token': token,
          'user_id': user.id,
          'platform': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (error) {
      debugPrint('Gagal menyimpan token: $error');
    }
  }
}
