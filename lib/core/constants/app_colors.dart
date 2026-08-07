import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Deep Elegant Gold & Royal Navy)
  static const Color primary = Color(0xFFB38E44); // Deep Gold
  static const Color secondary = Color(0xFF1A2A40); // Royal Navy
  static const Color secondaryDark = Color(0xFF0F1926);
  static const Color secondaryLight = Color(0xFF2C3E50);

  static const Color gold = Color(0xFFB38E44);
  static const Color goldLight = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF8E6D2D);

  // Background & Surfaces - أفتح وأوضح
  static const Color background = Color(0xFFF5F5F0); // Off-White دافئ
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF0EDE5);
  static const Color cardBackground = Color(0xFFFFFFFF); // كروت بيضاء
  static const Color outline = Color(0xFFD1CFCA);
  static const Color divider = Color(0xFFEEEEEE);

  // Text Colors - تباين عالي
  static const Color textPrimary = Color(0xFF1A2A40); // داكن للنصوص
  static const Color textSecondary = Color(0xFF5D6D7E); // رمادي متوسط
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF); // نص على خلفية داكنة

  // Semantic
  static const Color error = Color(0xFFC0392B);
  static const Color success = Color(0xFF27AE60);
  static const Color info = Color(0xFF2980B9);
  static const Color warning = Color(0xFFF39C12);

  // Status Badge Colors - واضحة وجميلة
  static const Color pendingBg = Color(0xFFFFF3CD);
  static const Color pendingText = Color(0xFF856404);
  static const Color acceptedBg = Color(0xFFD1ECF1);
  static const Color acceptedText = Color(0xFF0C5460);
  static const Color cancelledBg = Color(0xFFF8D7DA);
  static const Color cancelledText = Color(0xFF721C24);

  // Gradients - للـ Header فقط
  static const List<Color> brandGradient = [
    Color(0xFF1A2A40),
    Color(0xFF2C3E50),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFB38E44),
    Color(0xFF8E6D2D),
  ];
}
