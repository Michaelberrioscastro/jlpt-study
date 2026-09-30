import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8F4EE);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF7467A8);
  static const primarySoft = Color(0xFFEAE5F5);
  static const text = Color(0xFF29272D);
  static const muted = Color(0xFF77727D);
  static const border = Color(0xFFE7E0D8);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
      ),
    );
  }
}
