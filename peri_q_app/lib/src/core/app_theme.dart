import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

abstract final class AppRadii {
  static const double input = 12;
  static const double card = 16;
  static const double panel = 20;
  static const double pill = 999;
}

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

    const headingFamily = 'sans-serif-condensed';
    const bodyFamily = 'sans-serif';
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 31,
        fontWeight: FontWeight.w700,
        color: smokeCharcoal,
      ),
      headlineLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 27,
        fontWeight: FontWeight.w600,
        color: smokeCharcoal,
      ),
      headlineMedium: TextStyle(
        fontFamily: headingFamily,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: smokeCharcoal,
      ),
      titleLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: smokeCharcoal,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        height: 1.35,
        color: smokeCharcoal,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        height: 1.35,
        color: ashGrey,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12,
        height: 1.3,
        color: ashGrey,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: lightSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFamily,
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
          borderRadius: BorderRadius.circular(AppRadii.card),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
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
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
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
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      dividerColor: mutedSurface,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: periRed,
        linearTrackColor: mutedSurface,
        circularTrackColor: mutedSurface,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: smokeCharcoal,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}
