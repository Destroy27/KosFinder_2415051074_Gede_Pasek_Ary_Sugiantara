import 'package:flutter/material.dart';

import '../core/messages.dart';
import '../models/kos.dart';
import '../services/auth_service.dart';
import '../services/kos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kos_card.dart';
import 'kos_detail_page.dart';
import 'kos_form_page.dart';

class MyKosPage extends StatefulWidget {
  const MyKosPage({super.key});

  @override
  State<MyKosPage> createState() => _MyKosPageState();
}

class _MyKosPageState extends State<MyKosPage> {
  final KosService _service = KosService();

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
      final List<Kos> items = await _service.fetchMine();
      if (!mounted) return;
      setState(() {
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

  Future<void> _openForm({Kos? kos}) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted ? 'Kos dihapus.' : 'Penghapusan ditolak oleh RLS.',
          ),
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
      appBar: AppBar(title: const Text('Kos Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_work_outlined, size: 20),
        label: const Text('Tambah Kos'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.forest,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: <Widget>[
            const Text(
              'Hanya kos dengan owner_id milik akunmu yang dapat diubah '
              'atau dihapus. Percobaan terhadap kos orang lain akan ditolak '
              'oleh policy database.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Data belum bisa dimuat',
                message: _error!,
              )
            else if (_items.isEmpty)
              const _EmptyState(
                icon: Icons.home_work_outlined,
                title: 'Belum ada kos milikmu',
                message: 'Tekan "Tambah Kos" untuk memasarkan kos pertamamu.',
              )
            else
              ..._items.map(
                (Kos kos) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KosCard(
                    kos: kos,
                    currentUserId: userId,
                    onTap: () => Navigator.of(context)
                        .push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => KosDetailPage(kosId: kos.id),
                          ),
                        )
                        .then((_) {
                          if (mounted) _load();
                        }),
                    onEdit: () => _openForm(kos: kos),
                    onDelete: () => _delete(kos),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 30, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
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
    );
  }
}
