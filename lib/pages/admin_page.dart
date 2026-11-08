import 'package:flutter/material.dart';

import '../core/messages.dart';
import '../models/kos.dart';
import '../services/auth_service.dart';
import '../services/kos_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kos_card.dart';

/// Halaman khusus admin: melihat seluruh data dan memverifikasi kos.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final KosService _service = KosService();
  final ProfileService _profileService = ProfileService();

  String _role = 'seeker';
  List<Kos> _items = <Kos>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final UserProfile? profile = await _profileService.getMyProfile();
      if (!mounted) return;
      if (profile?.isAdmin != true) {
        setState(() {
          _role = profile?.role ?? 'seeker';
          _loading = false;
        });
        return;
      }

      final List<Kos> items = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _role = 'admin';
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyDatabaseMessage(error);
        _loading = false;
      });
    }
  }

  Future<void> _toggleVerified(Kos kos) async {
    try {
      await _service.setVerified(kos.id, !kos.isVerified);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kos.isVerified
                ? 'Verifikasi ${kos.name} dibatalkan.'
                : '${kos.name} diverifikasi.',
          ),
        ),
      );
      _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyDatabaseMessage(error))));
    }
  }

  Future<void> _delete(Kos kos) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus kos?'),
        content: Text('${kos.name} akan dihapus permanen oleh admin.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final bool deleted = await _service.delete(kos.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deleted ? 'Kos dihapus.' : 'Aksi ditolak oleh RLS.'),
        ),
      );
      if (deleted) _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyDatabaseMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = AuthService.instance.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data (Admin)')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.forest,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: <Widget>[
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_role != 'admin')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.lock_outline,
                        size: 32,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Akses ditolak',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Halaman ini hanya untuk role admin. Role akunmu: $_role. '
                        'Policy RLS pada database juga akan menolak operasi ini.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              )
            else ...<Widget>[
              Text(
                '${_items.length} data kos terdaftar. Admin dapat '
                'memverifikasi dan menghapus data sesuai kebijakan aplikasi.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              ..._items.map(
                (Kos kos) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KosCard(
                    kos: kos,
                    currentUserId: userId,
                    onToggleVerified: () => _toggleVerified(kos),
                    onDelete: () => _delete(kos),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
