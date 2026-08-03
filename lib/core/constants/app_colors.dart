import 'package:flutter/material.dart';

class AppColors {
  // Primary & Brand Colors
  static const Color primary = Color(0xFF0F1D3A); // Navy
  static const Color secondary = Color(0xFFC9A84C); // Gold
  static const Color accent = Color(0xFF1B4F8A); // Blue
  static const Color gold = Color(0xFFC9A84C); // Gold

  // Neutral Surfaces (Cream & Warm palette)
  static const Color background = Color(0xFFF8F5EF); // Cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8E0D0); // Warm
  static const Color outline = Color(0xFF888888);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF2E7D32);

  // Functional Tones
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF0F1D3A);
  static const Color primaryContainer = Color(0xFF1B4F8A);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Gradients (From Design System)
  static const List<Color> loginGradient = [
    Color(0xFF0F1D3A),
    Color(0xFF1B4F8A),
  ];

  static const List<Color> detailsGradient = [
    Color(0xFF0F1D3A),
    Color(0xFF1B4F8A),
  ];
}
