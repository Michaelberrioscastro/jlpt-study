import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand — Japanese premium identity
  static const primary = Color(0xFF19324A); // Ink navy
  static const primaryStrong = Color(0xFF102536); // Deep ink
  static const primarySoft = Color(0xFFDCE5EC); // Mist blue
  static const primaryContainer = Color(0xFFE8EEF2); // Pale ink wash

  // Supporting accents
  static const sage = Color(0xFF5E776B);
  static const sageSoft = Color(0xFFE4ECE7);

  static const blue = Color(0xFF315B7A);
  static const blueSoft = Color(0xFFE0E9EF);

  // Functional gold is intentionally darker for legibility.
  static const gold = Color(0xFF8F692F);
  static const goldSoft = Color(0xFFF1E6CB);

  // Decorative brand accents from the new logo.
  static const brandGold = Color(0xFFC7A15B);
  static const vermilion = Color(0xFFB84B3A);
  static const vermilionSoft = Color(0xFFF3DED8);

  // Surfaces — warm paper / ivory
  static const background = Color(0xFFF6F1E8);
  static const surface = Color(0xFFFFFCF6);
  static const surfaceSoft = Color(0xFFEDE7DC);
  static const surfaceMuted = Color(0xFFE2DBD0);

  // Text
  static const textPrimary = Color(0xFF1F2A30);
  static const textSecondary = Color(0xFF5B686F);
  static const textMuted = Color(0xFF7C858A);

  // Semantic
  static const success = Color(0xFF5E776B);
  static const warning = Color(0xFF8F692F);
  static const error = Color(0xFFB84B3A);

  // Borders / dividers
  static const outline = Color(0xFFD8D0C3);
  static const divider = Color(0xFFE5DED3);
}
