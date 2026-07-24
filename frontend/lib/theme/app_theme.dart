import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const ink = Color(0xFF080B12);
  static const panel = Color(0xFF101722);
  static const panelAlt = Color(0xFF151D2A);
  static const stroke = Color(0xFF263244);
  static const text = Color(0xFFE8EEF7);
  static const muted = Color(0xFF91A0B8);
  static const faint = Color(0xFF5E6D83);
  static const cyan = Color(0xFF20C7E8);
  static const green = Color(0xFF36D399);
  static const red = Color(0xFFFF4D67);
  static const orange = Color(0xFFFFB454);
  static const violet = Color(0xFF9D8CFF);
}

class AppRadii {
  static const small = 6.0;
  static const panel = 8.0;
}

class AppBorders {
  static const subtle = BorderSide(color: AppColors.stroke);
}

ThemeData buildShieldScanTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ink,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.green,
      error: AppColors.red,
      surface: AppColors.panel,
      onSurface: AppColors.text,
    ),
    textTheme: textTheme.copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1.1,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: 0,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        color: AppColors.text,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        side: AppBorders.subtle,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ink,
      contentPadding: const EdgeInsets.all(14),
      hintStyle: GoogleFonts.spaceGrotesk(
        color: AppColors.faint,
        fontSize: 13,
        letterSpacing: 0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        borderSide: AppBorders.subtle,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        borderSide: AppBorders.subtle,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.4),
      ),
    ),
  );
}
