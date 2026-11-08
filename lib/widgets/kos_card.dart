import 'package:flutter/material.dart';

import '../models/kos.dart';
import '../theme/app_theme.dart';

/// Kartu ringkas satu data kos.
class KosCard extends StatelessWidget {
  const KosCard({
    super.key,
    required this.kos,
    required this.currentUserId,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleVerified,
  });

  final Kos kos;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleVerified;

  @override
  Widget build(BuildContext context) {
    final bool isMine = kos.isOwnedBy(currentUserId);
    final bool hasMenu = onEdit != null || onDelete != null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            kos.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (kos.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
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
                    const SizedBox(height: 4),
                    Text(
                      kos.address.isEmpty ? 'Alamat belum diisi' : kos.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Text(
                          kos.priceLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                        if (isMine) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.peach,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Milik saya',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (hasMenu)
                PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                      case 'verify':
                        onToggleVerified?.call();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        if (onEdit != null)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Ubah'),
                          ),
                        if (onToggleVerified != null)
                          PopupMenuItem<String>(
                            value: 'verify',
                            child: Text(
                              kos.isVerified
                                  ? 'Batalkan verifikasi'
                                  : 'Verifikasi',
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                      ],
                )
              else
                const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
