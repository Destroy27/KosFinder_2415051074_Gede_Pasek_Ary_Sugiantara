import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna KosFinder: kertas hangat, tinta gelap, dan aksen pastel.
class AppColors {
  const AppColors._();

  static const Color paper = Color(0xFFF7F5F0);
  static const Color ink = Color(0xFF1F2023);
  static const Color forest = Color(0xFF2F5D50);
  static const Color sage = Color(0xFFDCE9E1);
  static const Color peach = Color(0xFFF4E1D2);
  static const Color muted = Color(0xFF6F7075);
  static const Color border = Color(0xFFE4DFD5);
  static const Color danger = Color(0xFF9B3B33);
  static const Color success = Color(0xFF2E6B4F);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
      surface: AppColors.paper,
      primary: AppColors.forest,
    ).copyWith(outlineVariant: AppColors.border, error: AppColors.danger);

    final TextTheme textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sage,
        side: BorderSide.none,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
      ),
    );
  }
}
