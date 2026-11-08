import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kos.dart';

/// Akses data tabel `kos`.
///
/// Semua aturan kepemilikan tetap ditegakkan oleh Row Level Security di
/// database. Service ini hanya menyediakan operasi dan membaca hasilnya.
class KosService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<Kos>> fetchAll({String keyword = ''}) async {
    var query = _client.from('kos').select();

    if (keyword.trim().isNotEmpty) {
      final String term = keyword.trim();
      query = query.or('name.ilike.%$term%,address.ilike.%$term%');
    }

    final List<Map<String, dynamic>> data = await query.order(
      'created_at',
      ascending: false,
    );
    return data.map(Kos.fromMap).toList();
  }

  Future<List<Kos>> fetchMine() async {
    final List<Map<String, dynamic>> data = await _client
        .from('kos')
        .select()
        .eq('owner_id', _uid)
        .order('created_at', ascending: false);
    return data.map(Kos.fromMap).toList();
  }

  Future<Kos?> fetchById(String id) async {
    final Map<String, dynamic>? data = await _client
        .from('kos')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : Kos.fromMap(data);
  }

  Future<void> add({
    required String name,
    required String address,
    required int price,
    required String description,
  }) async {
    await _client.from('kos').insert(<String, dynamic>{
      'owner_id': _uid,
      'name': name,
      'address': address,
      'price': price,
      'description': description,
    });
  }

  /// Mengembalikan `true` bila baris benar-benar berubah.
  ///
  /// Ketika operasi ditolak RLS, Supabase tidak melempar error: hasilnya
  /// berupa daftar kosong. Karena itu hasil `select()` wajib diperiksa.
  Future<bool> update(String id, Map<String, dynamic> values) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('kos')
        .update(values)
        .eq('id', id)
        .select();
    return rows.isNotEmpty;
  }

  Future<bool> delete(String id) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('kos')
        .delete()
        .eq('id', id)
        .select();
    return rows.isNotEmpty;
  }

  Future<void> setVerified(String id, bool value) async {
    await _client.from('kos').update({'is_verified': value}).eq('id', id);
  }
}
