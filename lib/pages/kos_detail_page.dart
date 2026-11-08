import 'package:flutter/material.dart';

import '../core/messages.dart';
import '../models/kos.dart';
import '../services/auth_service.dart';
import '../services/kos_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'kos_form_page.dart';

class KosDetailPage extends StatefulWidget {
  const KosDetailPage({super.key, required this.kosId});

  final String kosId;

  @override
  State<KosDetailPage> createState() => _KosDetailPageState();
}

class _KosDetailPageState extends State<KosDetailPage> {
  final KosService _service = KosService();
  final ProfileService _profileService = ProfileService();

  Kos? _kos;
  String _role = 'seeker';
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
      final Kos? kos = await _service.fetchById(widget.kosId);
      if (!mounted) return;
      setState(() {
        _role = profile?.role ?? 'seeker';
        _kos = kos;
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

  Future<void> _edit(Kos kos) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => KosFormPage(kos: kos)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Kos kos) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus kos?'),
        content: Text('${kos.name} akan dihapus permanen.'),
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
      if (deleted) {
        Navigator.of(context).pop();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penghapusan ditolak oleh RLS.')),
      );
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
    final Kos? kos = _kos;
    final bool canManage =
        kos != null && (kos.isOwnedBy(userId) || _role == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kos'),
        actions: <Widget>[
          if (canManage)
            IconButton(
              tooltip: 'Ubah',
              onPressed: () => _edit(kos),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          if (canManage)
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => _delete(kos),
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_outlined, size: 32),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    final Kos? kos = _kos;
    if (kos == null) {
      return const Center(child: Text('Kos tidak ditemukan.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        kos.name,
                        style: const TextStyle(
                          fontSize: 21,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (kos.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Terverifikasi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  kos.priceLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: 'Alamat',
                  value: kos.address.isEmpty ? '-' : kos.address,
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Deskripsi',
                  value: kos.description.isEmpty
                      ? 'Belum ada deskripsi.'
                      : kos.description,
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  icon: Icons.fingerprint,
                  label: 'Owner ID',
                  value: kos.ownerId,
                  mono: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: AppColors.sage.withValues(alpha: 0.5),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 18, color: AppColors.forest),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data ini dilindungi RLS. Pengguna lain hanya dapat '
                    'membaca, tidak dapat mengubah atau menghapus.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.ink,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
