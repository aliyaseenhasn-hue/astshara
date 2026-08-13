import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  static const double _borderRadius = 16.0;

  static ThemeData get light {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.goldLight,
        onPrimaryContainer: AppColors.secondary,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE8EEF3),
        onSecondaryContainer: AppColors.secondary,
        surface: AppColors.surface,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFFCFAF6),
        surfaceContainer: AppColors.background,
        surfaceContainerHigh: Color(0xFFF6F2E9),
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
        outlineVariant: AppColors.divider,
        error: AppColors.error,
        onError: Colors.white,
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
        surfaceTintColor: Colors.transparent,
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
        margin: const EdgeInsets.symmetric(vertical: 6),
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
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16),
          ),
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
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14),
          ),
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary, linearTrackColor: AppColors.primaryLight),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColors.textOnPrimary),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(AppColors.primary)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.outline),
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTheme.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  static ThemeData get dark {
    const darkBackground = Color(0xFF0B121A);
    const darkSurface = Color(0xFF121D28);
    const darkSurfaceVariant = Color(0xFF1A2A38);
    const darkOutline = Color(0xFF355064);
    const darkTextPrimary = Color(0xFFF4F8FB);
    const darkTextSecondary = Color(0xFFB7C7D3);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      dividerColor: const Color(0xFF233543),
      splashFactory: InkRipple.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: Color(0xFF164A61),
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.gold,
        onSecondary: Color(0xFF2B250E),
        secondaryContainer: Color(0xFF514719),
        onSecondaryContainer: AppColors.goldLight,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkTextSecondary,
        outline: darkOutline,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.primaryLight),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 18, fontWeight: FontWeight.bold, color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius), side: const BorderSide(color: darkOutline, width: 1)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? const Color(0xFF2A3945) : states.contains(WidgetState.pressed) ? AppColors.primaryDark : AppColors.primary),
          foregroundColor: const WidgetStatePropertyAll(AppColors.textOnPrimary),
          overlayColor: const WidgetStatePropertyAll(Color(0x33FFFFFF)),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 16)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.goldLight),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.primary, width: 1.5)),
          overlayColor: const WidgetStatePropertyAll(Color(0x335EC8F2)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryLight),
          overlayColor: const WidgetStatePropertyAll(Color(0x335EC8F2)),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkOutline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        labelStyle: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        prefixIconColor: AppColors.primaryLight,
        suffixIconColor: AppColors.primaryLight,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: darkSurface,
        iconColor: AppColors.primaryLight,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, fontSize: 15, color: darkTextPrimary),
        subtitleTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12, color: darkTextSecondary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold, linearTrackColor: darkSurfaceVariant),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(AppColors.primary)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.gold : darkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? const Color(0x66F4D06F) : darkSurfaceVariant),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF233543), thickness: 1),
      iconTheme: const IconThemeData(color: AppColors.primaryLight),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.gold, foregroundColor: Color(0xFF2B250E)),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTheme.textTheme).apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
    );
  }
}
