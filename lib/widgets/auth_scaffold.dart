import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kerangka halaman autentikasi agar Login dan Register tampil konsisten.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _BrandMark(),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: child,
                    ),
                  ),
                  if (footer != null) ...<Widget>[
                    const SizedBox(height: 18),
                    Center(child: footer!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.cottage_outlined,
            color: AppColors.forest,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'KosFinder',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.ink,
              ),
            ),
            Text(
              'Cari kos, kelola kos.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}
