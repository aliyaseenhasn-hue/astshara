import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  static const double _borderRadius = 16.0;

  static ThemeData get light {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        outline: AppColors.outline,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textOnPrimary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.divider,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.outline;
            if (states.contains(WidgetState.pressed)) return AppColors.primaryDark;
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(AppColors.textOnPrimary),
          overlayColor: const WidgetStatePropertyAll(Color(0x2296D9F5)),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: const WidgetStatePropertyAll(0),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryDark),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.primary, width: 1.5)),
          overlayColor: const WidgetStatePropertyAll(Color(0x2296D9F5)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14)),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryDark),
          overlayColor: const WidgetStatePropertyAll(Color(0x2296D9F5)),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 14),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        subtitleTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: AppColors.textSecondary),
        iconColor: AppColors.primaryDark,
        tileColor: AppColors.surface,
      ),
    );

    return baseTheme.copyWith(textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTheme.textTheme).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary));
  }

  static ThemeData get dark {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1419),
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark, primary: AppColors.primary, surface: const Color(0xFF15202B)),
    );
    return baseTheme.copyWith(textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTheme.textTheme));
  }
}
