import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors (Matrimony Pink & Gold Accents)
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFF8BBD0);
  static const Color secondary = Color(0xFFFF9800);
  static const Color accentGold = Color(0xFFFFD700);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFDF7F8);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Status & Utility
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color border = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFF0F0F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFFF4081), Color(0xFFFF80AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
