/// Konfigurasi Supabase untuk project KosFinder (Worksheet 9).
///
/// Cara mengisi:
/// 1. Buka https://supabase.com/dashboard lalu buat project baru (atau pakai
///    project yang sudah ada).
/// 2. Masuk ke SQL Editor, jalankan seluruh isi file `tugas9_supabase.sql`
///    yang ada di root project ini.
/// 3. Masuk ke Project Settings > API Keys:
///    - Salin Project URL ke [url].
///    - Salin `anon` / `publishable` key ke [publishableKey].
/// 4. Hot restart aplikasi (tekan `R` di terminal `flutter run`).
///
/// CATATAN KEAMANAN:
/// - Jangan pernah memakai `service_role` / secret key di aplikasi Flutter.
/// - Key `anon`/publishable aman dipakai di client selama Row Level Security
///   (RLS) aktif, seperti yang diterapkan pada file SQL di atas.
class SupabaseConfig {
  const SupabaseConfig._();

  /// Contoh: 'https://abcdefghijklm.supabase.co'
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Contoh: 'sb_publishable_xxxxxxxxxxxxxxxxxxxx'
  static const String publishableKey = 'YOUR_SUPABASE_PUBLISHABLE_KEY';

  /// Nama tabel utama pada database PostgreSQL Supabase.
  static const String kosTable = 'kos';
  static const String profilesTable = 'profiles';
  static const String deviceTokensTable = 'device_tokens';

  /// Mengecek apakah kredensial Supabase sudah diisi.
  static bool get isConfigured =>
      url.isNotEmpty &&
      publishableKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT_ID') &&
      !publishableKey.contains('YOUR_SUPABASE');
}
