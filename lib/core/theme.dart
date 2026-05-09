import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const Color background       = Color(0xFF0E140C);
  static const Color surface          = Color(0xFF161E12);
  static const Color surfaceHighlight = Color(0xFF2C2F1F);
  static const Color gold             = Color(0xFFC9A97A);
  static const Color textMuted        = Color(0xFF5A5F52);
  static const Color textPrimary      = Color(0xFFD1CFC0);
  static const Color cardBorder       = Color(0xFF293225);
}

abstract final class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
    color: AppColors.textPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get heading => GoogleFonts.cormorantGaramond(
    color: AppColors.textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get label => GoogleFonts.dmSans(
    color: AppColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
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
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
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
  cardTheme: const CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.gold,
    unselectedItemColor: AppColors.textMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 11),
    unselectedLabelStyle: TextStyle(fontSize: 11),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.surfaceHighlight,
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
