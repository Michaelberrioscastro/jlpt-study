import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

abstract final class AppColors {
  static const background = Color(0xFF090E1D);
  static const surface = Color(0xFF121A2E);
  static const surface2 = Color(0xFF18233B);
  static const ink = Color(0xFFF7F8FC);
  static const muted = Color(0xFFA9B2C7);
  static const border = Color(0xFF2A3654);

  static const navy = Color(0xFF090E1D);
  static const navySoft = Color(0xFF1B2745);
  static const coral = Color(0xFFFF6B68);
  static const coralSoft = Color(0xFF3B222B);
  static const mint = Color(0xFF56CDB4);
  static const mintSoft = Color(0xFF173B3A);
  static const violet = Color(0xFF9585FF);
  static const violetSoft = Color(0xFF292447);
  static const yellow = Color(0xFFFFC857);
  static const yellowSoft = Color(0xFF3B311C);
  static const redSoft = Color(0xFF3D2229);
  static const green = Color(0xFF46B98E);
  static const sakura = Color(0xFFF08CA4);

  // Compatibility aliases for the current app shell.
  static const primary = violet;
  static const primaryDeep = navy;
  static const primarySoft = violetSoft;
  static const roseSoft = coralSoft;
  static const sageSoft = mintSoft;
  static const text = ink;
  static const mutedText = muted;
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: AppColors.violet,
        onPrimary: Colors.white,
        secondary: AppColors.coral,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        surfaceTint: Colors.transparent,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'Roboto',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: -1.5),
        headlineMedium: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: -1.0),
        headlineSmall: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: -.5),
        titleLarge: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        titleMedium: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(color: AppColors.ink, height: 1.4),
        bodyMedium: TextStyle(color: AppColors.ink, height: 1.4),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.violetSoft,
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.violetSoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.violet,
        linearTrackColor: AppColors.border,
      ),
    );
  }
}
