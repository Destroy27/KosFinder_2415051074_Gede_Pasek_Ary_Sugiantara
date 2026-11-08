import 'package:supabase_flutter/supabase_flutter.dart';

/// Profil pengguna beserta role-nya.
///
/// Role disimpan di tabel `profiles`, bukan di metadata yang bisa diubah
/// sendiri oleh pengguna melalui aplikasi.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String role;

  bool get isSeeker => role == 'seeker';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManageKos => isOwner || isAdmin;

  String get displayName => name.trim().isEmpty ? email : name;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      role: (map['role'] ?? 'seeker') as String,
    );
  }
}

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserProfile?> getMyProfile() async {
    final User? user = _client.auth.currentUser;
    if (user == null) return null;

    final Map<String, dynamic>? data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) return UserProfile.fromMap(data);

    // Cadangan: jika trigger profiles belum sempat berjalan, tetap tampilkan
    // data dari sesi agar pengguna tidak terjebak di layar kosong.
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      name: (user.userMetadata?['name'] ?? '') as String,
      role: 'seeker',
    );
  }

  /// Mengubah nama tampilan milik sendiri (role tidak boleh diubah dari app).
  Future<void> updateMyName(String name) async {
    final User? user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({'name': name}).eq('id', user.id);
  }
}
