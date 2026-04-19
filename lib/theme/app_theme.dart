import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D0D0F);
  static const surface    = Color(0xFF1A1A1E);
  static const card       = Color(0xFF222228);
  static const accent     = Color(0xFFFF6B6B);
  static const accentWarm = Color(0xFFFF8E53);
  static const like       = Color(0xFF4ECDC4);
  static const dislike    = Color(0xFFFF6B6B);
  static const textPrim   = Color(0xFFF5F0E8);
  static const textSec    = Color(0xFF9A9A9A);
  static const divider    = Color(0xFF2E2E36);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.accent,
      secondary: AppColors.accentWarm,
      surface:   AppColors.surface,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrim,
    ),
    fontFamily: 'DMSans',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlayfairDisplay',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrim,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrim),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSec,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textSec),
      labelStyle: const TextStyle(color: AppColors.textSec),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
  );
}
