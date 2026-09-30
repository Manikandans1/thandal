import 'package:flutter/material.dart';

/// Central color palette matching the Thandal admin app screens:
/// deep forest-green primary, light mint accents, amber "needs attention"
/// banners, and red danger actions.
class AppColors {
  AppColors._();

  static const Color primaryDark = Color(0xFF0A3F30); // splash / headers
  static const Color primary = Color(0xFF0F6B4C); // buttons / active states
  static const Color primaryLight = Color(0xFFE3F3EC); // light green tint
  static const Color primaryLighter = Color(0xFFF0F9F5);

  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE6E8EB);
  static const Color divider = Color(0xFFEEF0F2);

  static const Color textPrimary = Color(0xFF1B2126);
  static const Color textSecondary = Color(0xFF6C7580);
  static const Color textMuted = Color(0xFF9AA3AC);

  static const Color danger = Color(0xFFD8342A);
  static const Color dangerLight = Color(0xFFFCEAE8);

  static const Color warning = Color(0xFFB4790A);
  static const Color warningLight = Color(0xFFFCF0D9);
  static const Color warningBorder = Color(0xFFF0DBA6);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFE8F0FE);

  static const Color chipInactiveBg = Color(0xFFF0F1F3);
  static const Color chipInactiveText = Color(0xFF6C7580);
}

class AppStatus {
  static Color bg(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'completed':
      case 'paid':
      case 'approved':
        return AppColors.primaryLight;
      case 'inactive':
      case 'rejected':
      case 'overdue':
      case 'failed':
        return AppColors.dangerLight;
      case 'pending':
      case 'upcoming':
      case 'today':
        return AppColors.warningLight;
      case 'unassigned':
        return AppColors.chipInactiveBg;
      default:
        return AppColors.chipInactiveBg;
    }
  }

  static Color fg(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'completed':
      case 'paid':
      case 'approved':
        return AppColors.primary;
      case 'inactive':
      case 'rejected':
      case 'overdue':
      case 'failed':
        return AppColors.danger;
      case 'pending':
      case 'upcoming':
      case 'today':
        return AppColors.warning;
      case 'unassigned':
        return AppColors.chipInactiveText;
      default:
        return AppColors.chipInactiveText;
    }
  }
}
