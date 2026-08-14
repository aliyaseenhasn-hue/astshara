import 'package:flutter/material.dart';

/// Premium Legal Narrative palette.
/// Deep navy = authority, gold = premium actions, teal = digital accents.
class AppColors {
  // Core brand
  static const Color primary = Color(0xFF001428);
  static const Color primaryDark = Color(0xFF0F2942);
  static const Color primaryLight = Color(0xFF7991AF);

  static const Color secondary = Color(0xFF735C00);
  static const Color secondaryDark = Color(0xFF574500);
  static const Color secondaryLight = Color(0xFFE9C349);

  static const Color gold = Color(0xFFE9C349);
  static const Color goldLight = Color(0xFFFFE088);
  static const Color goldDark = Color(0xFF745C00);

  static const Color tertiary = Color(0xFF002D31);
  static const Color tertiaryLight = Color(0xFF4F9AA2);
  static const Color teal = Color(0xFF2E7D85);

  // Surfaces
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFD9DADB);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);

  // Text and structure
  static const Color textPrimary = Color(0xFF191C1D);
  static const Color textSecondary = Color(0xFF43474D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF0F1F2);
  static const Color outline = Color(0xFF74777E);
  static const Color divider = Color(0xFFC3C6CE);

  // Semantic colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF2E7D5B);
  static const Color info = Color(0xFF2E7D85);
  static const Color warning = Color(0xFF735C00);

  static const Color pendingBg = Color(0xFFFFF4D0);
  static const Color pendingText = Color(0xFF745C00);
  static const Color acceptedBg = Color(0xFFE8F3EA);
  static const Color acceptedText = Color(0xFF285F45);
  static const Color cancelledBg = Color(0xFFFFDAD6);
  static const Color cancelledText = Color(0xFF93000A);

  static const List<Color> brandGradient = [
    Color(0xFF001428),
    Color(0xFF0F2942),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFFFE088),
    Color(0xFFE9C349),
  ];

  static const List<Color> skyGradient = [
    Color(0xFFEAF2F7),
    Color(0xFFBFD5D8),
  ];
}
