import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF7F2EC);
  static const surface = Color(0xFFFFFCF9);
  static const primary = Color(0xFF6657A8);
  static const primaryDeep = Color(0xFF51428F);
  static const primarySoft = Color(0xFFEAE5F7);
  static const roseSoft = Color(0xFFF8E8E8);
  static const sageSoft = Color(0xFFE7F2E9);
  static const text = Color(0xFF29262F);
  static const muted = Color(0xFF77717C);
  static const border = Color(0xFFE7DED5);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surface),
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, foregroundColor: AppColors.text, elevation: 0),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.text, letterSpacing: -.7),
        headlineSmall: TextStyle(color: AppColors.text, letterSpacing: -.4),
        titleLarge: TextStyle(color: AppColors.text),
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: AppColors.border)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: AppColors.border), foregroundColor: AppColors.text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        elevation: 10,
        shadowColor: AppColors.primary.withOpacity(.08),
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary, linearTrackColor: Color(0xFFE7E0F1)),
    );
  }
}
