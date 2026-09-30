import 'package:flutter/material.dart';

/// Centralised colour palette sampled from the Thandal design.
class AppColors {
  AppColors._();

  // Brand green
  static const Color primaryDark = Color(0xFF0A4B37); // hero card / headers
  static const Color primary = Color(0xFF0E6E4F); // buttons, active states
  static const Color primaryDeep = Color(0xFF073B2C); // gradients / pressed
  static const Color lime = Color(0xFFCFF15A); // progress bar highlight

  // Neutrals
  static const Color background = Color(0xFFFFFFFF);
  static const Color scaffold = Color(0xFFF6F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E8E5);
  static const Color divider = Color(0xFFEEF1EF);
  static const Color textPrimary = Color(0xFF17211C);
  static const Color textSecondary = Color(0xFF6E7A73);
  static const Color textMuted = Color(0xFF9AA39D);

  // Avatar / soft green chips
  static const Color avatarBg = Color(0xFFE0F1E8);
  static const Color softGreenBg = Color(0xFFE7F5EC);

  // Status colours
  static const Color overdue = Color(0xFFD1483A);
  static const Color overdueBg = Color(0xFFFBEAE7);
  static const Color due = Color(0xFFB9791A);
  static const Color dueBg = Color(0xFFFCF1DA);
  static const Color success = Color(0xFF1D8A54);
  static const Color successBg = Color(0xFFE1F4E8);
  static const Color info = Color(0xFF9A6B1D);
  static const Color infoBg = Color(0xFFFDF3DE);
  static const Color danger = Color(0xFFC53B2E);
  static const Color dangerBg = Color(0xFFFCEAE8);
}
