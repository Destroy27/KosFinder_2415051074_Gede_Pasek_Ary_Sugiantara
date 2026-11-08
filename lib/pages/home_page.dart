import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/messages.dart';
import '../models/kos.dart';
import '../services/auth_service.dart';
import '../services/kos_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kos_card.dart';
import 'admin_page.dart';
import 'kos_detail_page.dart';
import 'kos_form_page.dart';
import 'login_page.dart';
import 'my_kos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final KosService _kosService = KosService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  UserProfile? _profile;
  List<Kos> _items = <Kos>[];
  bool _loading = true;
  String? _error;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService.instance.init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final UserProfile? profile = await _profileService.getMyProfile();
      final List<Kos> items = await _kosService.fetchAll(keyword: _keyword);
      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  Future<void> _reloadKos() async {
    try {
      final List<Kos> items = await _kosService.fetchAll(keyword: _keyword);
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyDatabaseMessage(error));
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _keyword = value;
      _reloadKos();
    });
  }

  Future<void> _openForm({Kos? kos}) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => KosFormPage(kos: kos)),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetail(Kos kos) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => KosDetailPage(kosId: kos.id)),
    );
    if (mounted) _load();
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
      final bool deleted = await _kosService.delete(kos.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? 'Kos berhasil dihapus.'
                : 'Penghapusan ditolak: data bukan milikmu.',
          ),
        ),
      );
      if (deleted) _reloadKos();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyDatabaseMessage(error))));
    }
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Keluar dari KosFinder?'),
        content: const Text('Session di perangkat ini akan dihapus.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserProfile? profile = _profile;
    final bool canManage = profile?.canManageKos ?? false;
    final String? userId = AuthService.instance.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KosFinder'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_home_work_outlined, size: 20),
              label: const Text('Tambah Kos'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.forest,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: <Widget>[
            if (profile != null) _ProfileHeader(profile: profile, kos: _items),
            if (profile != null) const SizedBox(height: 14),
            if (profile != null)
              _RoleMenu(
                profile: profile,
                onOpenMyKos: () => Navigator.of(context)
                    .push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const MyKosPage(),
                      ),
                    )
                    .then((_) {
                      if (mounted) _load();
                    }),
                onOpenAdmin: () => Navigator.of(context)
                    .push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminPage(),
                      ),
                    )
                    .then((_) {
                      if (mounted) _load();
                    }),
              ),
            const SizedBox(height: 14),
            const _NotificationPanel(),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama atau alamat kos',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _keyword = '';
                          setState(() {});
                          _reloadKos();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                const Text(
                  'Kos tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_items.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildList(userId),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String? userId) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _MessageCard(
        icon: Icons.cloud_off_outlined,
        title: 'Data belum bisa dimuat',
        message: _error!,
        actionLabel: 'Coba lagi',
        onAction: _load,
      );
    }

    if (_items.isEmpty) {
      return _MessageCard(
        icon: Icons.holiday_village_outlined,
        title: 'Belum ada kos',
        message: _keyword.isEmpty
            ? 'Belum ada data kos pada database. Pemilik kos dapat menambahkan data pertama.'
            : 'Tidak ada kos yang cocok dengan "$_keyword".',
      );
    }

    return Column(
      children: _items
          .map(
            (Kos kos) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KosCard(
                kos: kos,
                currentUserId: userId,
                onTap: () => _openDetail(kos),
                onEdit: kos.isOwnedBy(userId) || _profile?.isAdmin == true
                    ? () => _openForm(kos: kos)
                    : null,
                onDelete: kos.isOwnedBy(userId) || _profile?.isAdmin == true
                    ? () => _delete(kos)
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.kos});

  final UserProfile profile;
  final List<Kos> kos;

  String get _roleLabel {
    switch (profile.role) {
      case 'owner':
        return 'Pemilik kos';
      case 'admin':
        return 'Admin';
      default:
        return 'Pencari kos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int mine = kos.where((Kos item) => item.isOwnedBy(profile.id)).length;
    final String initial = profile.displayName.trim().isEmpty
        ? 'K'
        : profile.displayName.trim().substring(0, 1).toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 48,
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _roleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _Stat(label: 'Kos tersedia', value: '${kos.length}'),
                _Stat(label: 'Milik saya', value: '$mine'),
                _Stat(label: 'Role', value: profile.role),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _RoleMenu extends StatelessWidget {
  const _RoleMenu({
    required this.profile,
    required this.onOpenMyKos,
    required this.onOpenAdmin,
  });

  final UserProfile profile;
  final VoidCallback onOpenMyKos;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    if (profile.isSeeker) {
      return Card(
        color: AppColors.sage.withValues(alpha: 0.55),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline, size: 18, color: AppColors.forest),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kamu masuk sebagai pencari kos. Menu tambah dan kelola kos '
                  'hanya tersedia untuk pemilik kos.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: _ActionTile(
            icon: Icons.home_work_outlined,
            label: 'Kos Saya',
            onTap: onOpenMyKos,
          ),
        ),
        if (profile.isAdmin) ...<Widget>[
          const SizedBox(width: 12),
          Expanded(
            child: _ActionTile(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              onTap: onOpenAdmin,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.forest),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationService.instance,
      builder: (BuildContext context, Widget? child) {
        final NotificationService service = NotificationService.instance;
        final String? token = service.token;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.notifications_none,
                      size: 20,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Notifikasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      service.permission,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                if (token != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            token.length > 34
                                ? '${token.substring(0, 34)}...'
                                : token,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: token));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Token FCM disalin.'),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.copy_all_outlined,
                            size: 16,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (service.error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Firebase belum siap: ${service.error}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: <Widget>[
                    TextButton(
                      onPressed: service.requestPermission,
                      child: const Text('Minta izin'),
                    ),
                    TextButton(
                      onPressed: service.getToken,
                      child: const Text('Ambil token'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
