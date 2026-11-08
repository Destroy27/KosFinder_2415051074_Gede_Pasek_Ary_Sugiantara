import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../theme/app_theme.dart';

/// Ditampilkan ketika kredensial Supabase belum diisi, agar aplikasi tidak
/// crash dan pengguna tahu langkah yang harus dilakukan.
class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cottage_outlined,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'KosFinder',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Siapkan backend dulu',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aplikasi ini memakai Supabase untuk Authentication dan '
                    'database. Ikuti tiga langkah berikut, lalu jalankan ulang '
                    'aplikasi.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _Step(
                    number: '1',
                    title: 'Buat project Supabase',
                    body:
                        'Buka supabase.com/dashboard, buat project baru, lalu '
                        'masuk ke menu SQL Editor.',
                  ),
                  const _Step(
                    number: '2',
                    title: 'Jalankan SQL',
                    body:
                        'Copy seluruh isi file tugas9_supabase.sql pada folder '
                        'project, tempel di SQL Editor, lalu klik Run. File itu '
                        'membuat tabel profiles, kos, device_tokens, trigger, '
                        'dan policy RLS.',
                  ),
                  const _Step(
                    number: '3',
                    title: 'Isi kredensial',
                    body:
                        'Project Settings > API Keys: salin Project URL dan '
                        'publishable/anon key ke lib/config/supabase_config.dart.',
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'lib/config/supabase_config.dart',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            "static const String url = "
                            "'https://PROJECT_ID.supabase.co';\n"
                            "static const String publishableKey = "
                            "'sb_publishable_...';",
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              fontFamily: 'monospace',
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            SupabaseConfig.isConfigured
                                ? 'Kredensial terisi, tetapi koneksi gagal. '
                                      'Periksa URL/key dan status project.'
                                : 'Saat ini kredensial masih placeholder.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Jalankan ulang aplikasi'),
                        content: const Text(
                          'Setelah config diisi, tekan R di terminal '
                          'flutter run (hot restart), atau hentikan lalu '
                          'jalankan flutter run lagi.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Mengerti'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('Sudah diisi, apa selanjutnya?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 26,
                width: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
