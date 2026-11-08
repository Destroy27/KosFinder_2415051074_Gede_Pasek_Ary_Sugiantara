import 'package:supabase_flutter/supabase_flutter.dart';

/// Mengubah pesan error teknis menjadi kalimat yang mudah dipahami pengguna.
String friendlyAuthMessage(Object error) {
  if (error is AuthException) {
    final String message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox, atau nonaktifkan '
          '"Confirm email" di Supabase.';
    }
    if (message.contains('user already registered')) {
      return 'Email sudah terdaftar. Silakan masuk.';
    }
    if (message.contains('password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (message.contains('unable to validate email')) {
      return 'Format email tidak valid.';
    }
    if (message.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
    }
    return error.message;
  }
  return 'Terjadi kesalahan. Periksa koneksi internet lalu coba lagi.';
}

/// Pesan untuk error database, termasuk penolakan Row Level Security.
String friendlyDatabaseMessage(Object error) {
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return 'Operasi ditolak oleh Row Level Security (tidak punya izin).';
    }
    if (error.code == '23505') {
      return 'Data sudah ada.';
    }
    if (error.code == '42P01') {
      return 'Tabel belum tersedia. Jalankan tugas9_supabase.sql terlebih dahulu.';
    }
    return 'Database menolak permintaan: ${error.message}';
  }
  return 'Tidak dapat menghubungi database. Periksa koneksi internet.';
}
