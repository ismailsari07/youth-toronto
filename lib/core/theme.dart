import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color background       = Color(0xFF020A08);
  static const Color backgroundAlt    = Color(0xFF08150D);
  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface          = Color(0xFF08110C);
  static const Color surfaceElevated  = Color(0xFF11261A);
  static const Color surfaceHighlight = Color(0xFF111812); // compat alias
  // ── Accents ───────────────────────────────────────────────────────────────
  static const Color activeGlow       = Color(0x2EC8A96B);
  static const Color gold             = Color(0xFFE1B06F);
  static const Color goldSoft         = Color(0xFFB8924F);
  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFFF3E7D0);
  static const Color textSecondary    = Color(0xB8F3E7D0);
  static const Color textMuted        = Color(0x73F3E7D0);
  // ── Borders & dividers ────────────────────────────────────────────────────
  static const Color cardBorder       = Color(0x1FC4A878);
  static const Color divider          = Color(0x0FFFFFFF);
}

abstract final class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
    color: AppColors.textPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w400,
    height: 1.1,
  );

  static TextStyle get heading => GoogleFonts.cormorantGaramond(
    color: AppColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.15,
  );

  static TextStyle get label => GoogleFonts.dmSans(
    color: AppColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
  );

  static TextStyle get body => GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get timeDisplay => GoogleFonts.dmSans(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w300,
  );

  static TextStyle get goldAccent => GoogleFonts.dmSans(
    color: AppColors.gold,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
  );
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.gold,
    onPrimary: AppColors.background,
    onSurface: AppColors.textPrimary,
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.cardBorder, width: 1),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.gold,
    unselectedItemColor: AppColors.textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: GoogleFonts.dmSans(fontSize: 10),
    unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 10),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
);
