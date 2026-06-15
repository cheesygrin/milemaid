import 'package:flutter/material.dart';
import 'package:milemaid/core/models/trip.dart';

/// Premium color palette for MileMaid (Material 3 inspired).
class AppColors {
  AppColors._();

  // Primary brand
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryDark = Color(0xFF004ACC);
  static const Color primaryLight = Color(0xFF4D94FF);

  // Accent / success (Business miles)
  static const Color accent = Color(0xFF00C853);
  static const Color accentDark = Color(0xFF009E40);

  // Semantic
  static const Color personal = Color(0xFF7C4DFF);
  static const Color commute = Color(0xFFFF6D00);
  static const Color other = Color(0xFF607D8B);

  // UI - Light
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F7);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF4F6FA);

  static const Color textPrimary = Color(0xFF1A1C20);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF8A8F98);

  static const Color divider = Color(0xFFE0E3E8);
  static const Color border = Color(0xFFD1D5DB);

  // UI - Dark (for future dark theme)
  static const Color darkBackground = Color(0xFF0F1114);
  static const Color darkSurface = Color(0xFF1C1F26);
  static const Color darkSurfaceVariant = Color(0xFF2A2D35);
  static const Color darkSurfaceElevated = Color(0xFF252930);
  static const Color darkTextPrimary = Color(0xFFF1F3F7);
  static const Color darkTextSecondary = Color(0xFF9BA0AA);
  static const Color darkTextTertiary = Color(0xFF6C727E);
  static const Color darkDivider = Color(0xFF2F333B);

  // Status / feedback
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);

  // Map
  static const Color mapRouteFast = Color(0xFFE53935); // high speed
  static const Color mapRouteMedium = Color(0xFFFFB300);
  static const Color mapRouteSlow = Color(0xFF00C853); // low speed / stopped

  // Category color helper
  static Color forCategory(TripCategory category) {
    switch (category) {
      case TripCategory.business:
        return accent;
      case TripCategory.personal:
        return personal;
      case TripCategory.commute:
        return commute;
      case TripCategory.other:
        return other;
    }
  }
}
