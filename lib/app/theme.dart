import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  static const double _borderRadius = 12.0;

  static ThemeData get light {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: Color(0xFFFFF3C4),
        onPrimaryContainer: AppColors.secondary,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE6EEF4),
        onSecondaryContainer: AppColors.secondary,
        surface: AppColors.background,
        surfaceContainerLowest: AppColors.surface,
        surfaceContainerLow: Color(0xFFFCFBF8),
        surfaceContainer: Color(0xFFF7F5F0),
        surfaceContainerHigh: Color(0xFFF3F0EA),
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
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
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
          overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 15, height: 1.3),
          ),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: const WidgetStatePropertyAll(0),
          animationDuration: const Duration(milliseconds: 180),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.secondary),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.primary, width: 1.5)),
          overlayColor: const WidgetStatePropertyAll(Color(0x1AD4AF37)),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.secondary),
          overlayColor: const WidgetStatePropertyAll(Color(0x14D4AF37)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        labelStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: AppColors.textSecondary, fontSize: 14),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
        subtitleTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: AppColors.textSecondary),
        iconColor: AppColors.secondary,
        tileColor: AppColors.surface,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary, linearTrackColor: Color(0x33D4AF37)),
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
    const darkBackground = Color(0xFF111415);
    const darkSurface = Color(0xFF1D2021);
    const darkSurfaceVariant = Color(0xFF323536);
    const darkOutline = Color(0xFF42474D);
    const darkTextPrimary = Color(0xFFE1E3E4);
    const darkTextSecondary = Color(0xFFC2C7CE);
    const cyan = Color(0xFF45D8ED);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      dividerColor: const Color(0xFF2A2F31),
      splashFactory: InkRipple.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE9C349),
        onPrimary: Color(0xFF3C2F00),
        primaryContainer: Color(0xFFD4AF37),
        onPrimaryContainer: Color(0xFF554300),
        secondary: cyan,
        onSecondary: Color(0xFF00363D),
        secondaryContainer: Color(0xFF00444D),
        onSecondaryContainer: Color(0xFF98F0FF),
        surface: darkBackground,
        onSurface: darkTextPrimary,
        surfaceContainerLowest: Color(0xFF0C0F10),
        surfaceContainerLow: Color(0xFF191C1D),
        surfaceContainer: darkSurface,
        surfaceContainerHigh: Color(0xFF282A2B),
        surfaceContainerHighest: darkSurfaceVariant,
        onSurfaceVariant: darkTextSecondary,
        outline: darkOutline,
        outlineVariant: Color(0xFF42474D),
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
        iconTheme: const IconThemeData(color: Color(0xFFE9C349)),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 20, height: 1.4, fontWeight: FontWeight.w700, color: darkTextPrimary),
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
          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.disabled) ? const Color(0xFF2A2D2E) : states.contains(WidgetState.pressed) ? const Color(0xFFB48D19) : const Color(0xFFE9C349)),
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF3C2F00)),
          overlayColor: const WidgetStatePropertyAll(Color(0x33FFFFFF)),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(Color(0xFF98F0FF)),
          side: const WidgetStatePropertyAll(BorderSide(color: cyan, width: 1.5)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(Color(0xFFE9C349)),
          textStyle: WidgetStatePropertyAll(GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkOutline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF45D8ED), width: 2)),
        labelStyle: GoogleFonts.ibmPlexSansArabic(color: Color(0xFFE9C349), fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.ibmPlexSansArabic(color: darkTextSecondary, fontSize: 14),
        prefixIconColor: const Color(0xFFE9C349),
        suffixIconColor: const Color(0xFFE9C349),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: darkSurface,
        iconColor: const Color(0xFFE9C349),
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700, fontSize: 15, color: darkTextPrimary),
        subtitleTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13, color: darkTextSecondary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Color(0xFFE9C349), linearTrackColor: darkSurfaceVariant),
      dividerTheme: const DividerThemeData(color: Color(0xFF42474D), thickness: 1),
      iconTheme: const IconThemeData(color: Color(0xFFE9C349)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Color(0xFFE9C349), foregroundColor: Color(0xFF3C2F00)),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(baseTheme.textTheme).apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
    );
  }
}
