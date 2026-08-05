import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Deep Elegant Gold & Royal Navy)
  static const Color primary = Color(0xFFB38E44); // Deep Gold (أوضح للأزرار)
  static const Color secondary =
      Color(0xFF1A2A40); // Royal Navy (للأصالة والتباين العالي)
  static const Color secondaryDark = Color(0xFF0F1926);
  static const Color secondaryLight = Color(0xFF2C3E50);

  static const Color gold = Color(0xFFB38E44);
  static const Color goldLight = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF8E6D2D);

  // Background & Surfaces
  static const Color background = Color(0xFFF9F9F7); // Clean Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF0EDE5);
  static const Color outline = Color(0xFFD1CFCA);
  static const Color divider = Color(0xFFEEEEEE);

  // High Contrast Text Colors
  static const Color textPrimary =
      Color(0xFF1A2A40); // Deep Navy (واضح جداً للقراءة)
  static const Color textSecondary = Color(0xFF5D6D7E); // Slate Grey
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color error = Color(0xFFC0392B);
  static const Color success = Color(0xFF27AE60);
  static const Color info = Color(0xFF2980B9);

  // Gradients
  static const List<Color> brandGradient = [
    Color(0xFF1A2A40),
    Color(0xFF2C3E50),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFB38E44),
    Color(0xFF8E6D2D),
  ];
}
