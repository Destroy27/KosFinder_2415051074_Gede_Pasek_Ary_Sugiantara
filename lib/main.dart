import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_keys.dart';
import 'config/supabase_config.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/setup_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase hanya diinisialisasi bila konfigurasi platform tersedia
  // (google-services.json / GoogleService-Info.plist dari flutterfire configure).
  final bool firebaseReady = await _initFirebase();
  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final bool supabaseReady = await _initSupabase();
  if (supabaseReady) {
    AuthService.instance.listenAuthChanges();
  }

  runApp(KosFinderApp(supabaseReady: supabaseReady));
}

Future<bool> _initFirebase() async {
  if (kIsWeb) return false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    return true;
  } catch (error) {
    debugPrint('Firebase belum siap: $error');
    return false;
  }
}

Future<bool> _initSupabase() async {
  if (!SupabaseConfig.isConfigured) return false;
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    return true;
  } catch (error) {
    debugPrint('Supabase gagal diinisialisasi: $error');
    return false;
  }
}

class KosFinderApp extends StatelessWidget {
  const KosFinderApp({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KosFinder',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: AppTheme.light(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!supabaseReady) return const SetupPage();
    return AuthService.instance.isLoggedIn
        ? const HomePage()
        : const LoginPage();
  }
}
