import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color periRed = Color(0xFFC8240B);
  static const Color chesaOrange = Color(0xFFF07820);
  static const Color smokeCharcoal = Color(0xFF1A1A1A);
  static const Color ashGrey = Color(0xFF4A4A4A);
  static const Color creamWhite = Color(0xFFFFF8F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color mutedSurface = Color(0xFFF5F0ED);
  static const Color success = Color(0xFF2A8C5A);
  static const Color warning = Color(0xFFE8A400);
  static const Color info = Color(0xFF1A6AB1);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamWhite,
      colorScheme: const ColorScheme.light(
        primary: periRed,
        secondary: chesaOrange,
        surface: lightSurface,
      ),
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: smokeCharcoal,
      ),
      headlineLarge: GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: smokeCharcoal,
      ),
      headlineMedium: GoogleFonts.oswald(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: smokeCharcoal,
      ),
      titleLarge: GoogleFonts.oswald(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: smokeCharcoal,
      ),
      bodyLarge: GoogleFonts.nunitoSans(
        fontSize: 16,
        color: smokeCharcoal,
      ),
      bodyMedium: GoogleFonts.nunitoSans(
        fontSize: 14,
        color: ashGrey,
      ),
      bodySmall: GoogleFonts.nunitoSans(
        fontSize: 12,
        color: ashGrey,
      ),
      labelLarge: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: lightSurface,
      ),
      labelMedium: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: smokeCharcoal,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: periRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: periRed,
          foregroundColor: lightSurface,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: periRed,
          side: const BorderSide(color: periRed),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      dividerColor: mutedSurface,
    );
  }
}
