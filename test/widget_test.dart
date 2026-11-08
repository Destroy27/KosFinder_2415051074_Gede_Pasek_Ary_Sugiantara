import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/pages/setup_page.dart';
import 'package:kosfinder/theme/app_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('priceLabel menambahkan pemisah ribuan', () {
    const Kos kos = Kos(
      id: '1',
      ownerId: 'u1',
      name: 'Kos Melati',
      address: 'Singaraja',
      price: 750000,
      description: '',
      isVerified: false,
    );
    expect(kos.priceLabel, 'Rp 750.000 / bulan');
  });

  test('isOwnedBy hanya benar untuk owner yang sama', () {
    const Kos kos = Kos(
      id: '1',
      ownerId: 'u1',
      name: 'Kos Melati',
      address: 'Singaraja',
      price: 750000,
      description: '',
      isVerified: false,
    );
    expect(kos.isOwnedBy('u1'), isTrue);
    expect(kos.isOwnedBy('u2'), isFalse);
    expect(kos.isOwnedBy(null), isFalse);
  });

  testWidgets('SetupPage tampil saat kredensial belum diisi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const SetupPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Siapkan backend dulu'), findsOneWidget);
  });
}
