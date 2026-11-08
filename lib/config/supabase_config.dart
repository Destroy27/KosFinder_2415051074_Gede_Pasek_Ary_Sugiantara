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

  /// Project Supabase: KosFinder_2415051074_Gede_Pasek_Ary_Sugiantara
  /// Region: ap-northeast-1 (Tokyo)
  static const String url = 'https://hkhtsbtyhrrmpsuobnsx.supabase.co';

  /// Key publishable (aman di client selama RLS aktif).
  static const String publishableKey =
      'sb_publishable_OBy5eURx2Iw7SE4KZXT4HA_r-FE5Vxd';

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
