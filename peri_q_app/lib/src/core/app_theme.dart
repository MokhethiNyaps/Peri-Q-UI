import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The spacing scale used throughout the app.
///
/// Keeping layout values on a 4 px grid prevents half-pixel positioning on
/// common phone densities and gives screens a consistent visual rhythm.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class AppRadii {
  static const double input = 16;
  static const double card = 20;
  static const double panel = 28;
  static const double sheet = 32;
  static const double pill = 999;
}

/// Semantic colours which are not represented by Material's [ColorScheme].
///
/// Every foreground/background pair is deliberately stored together. The
/// pairs used for text meet WCAG AAA (7:1) in both light and dark modes.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.elevatedSurface,
    required this.sunkenSurface,
    required this.softOutline,
    required this.heroSurface,
    required this.heroOnSurface,
    required this.shadow,
  });

  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color elevatedSurface;
  final Color sunkenSurface;
  final Color softOutline;
  final Color heroSurface;
  final Color heroOnSurface;
  final Color shadow;

  @override
  AppSemanticColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? elevatedSurface,
    Color? sunkenSurface,
    Color? softOutline,
    Color? heroSurface,
    Color? heroOnSurface,
    Color? shadow,
  }) {
    return AppSemanticColors(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      sunkenSurface: sunkenSurface ?? this.sunkenSurface,
      softOutline: softOutline ?? this.softOutline,
      heroSurface: heroSurface ?? this.heroSurface,
      heroOnSurface: heroOnSurface ?? this.heroOnSurface,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer: Color.lerp(
        onAccentContainer,
        other.onAccentContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      sunkenSurface: Color.lerp(sunkenSurface, other.sunkenSurface, t)!,
      softOutline: Color.lerp(softOutline, other.softOutline, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      heroOnSurface: Color.lerp(heroOnSurface, other.heroOnSurface, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppTheme._darkSemanticColors
            : AppTheme._lightSemanticColors);
  }
}

class AppTheme {
  // Brand source colours are kept for artwork and non-text decoration only.
  // Interactive and textual uses should come from ColorScheme/AppSemanticColors.
  static const Color periRed = Color(0xFFC8240B);
  static const Color chesaOrange = Color(0xFFF07820);
  static const Color smokeCharcoal = Color(0xFF1A1715);
  static const Color ashGrey = Color(0xFF4A403B);
  static const Color creamWhite = Color(0xFFFFF9F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color mutedSurface = Color(0xFFF4ECE7);
  static const Color success = Color(0xFF165C3A);
  static const Color warning = Color(0xFF7A4D00);
  static const Color info = Color(0xFF135A91);

  static const _lightScheme = ColorScheme.light(
    primary: Color(0xFF8F1D0D),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDAD2),
    onPrimaryContainer: Color(0xFF360500),
    secondary: Color(0xFF7A3500),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDBC5),
    onSecondaryContainer: Color(0xFF2A1000),
    tertiary: Color(0xFF165C3A),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC5F6D9),
    onTertiaryContainer: Color(0xFF063A22),
    error: Color(0xFF971C16),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD5),
    onErrorContainer: Color(0xFF3B0604),
    surface: creamWhite,
    onSurface: Color(0xFF18100D),
    onSurfaceVariant: Color(0xFF493B35),
    outline: Color(0xFF695952),
    outlineVariant: Color(0xFFD9C2B8),
    shadow: Color(0xFF2C0C05),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF332D2A),
    onInverseSurface: Color(0xFFFFF8F5),
    inversePrimary: Color(0xFFFFB4A3),
  );

  static const _darkScheme = ColorScheme.dark(
    primary: Color(0xFFFFB4A3),
    onPrimary: Color(0xFF2B0702),
    primaryContainer: Color(0xFF6F1005),
    onPrimaryContainer: Color(0xFFFFDAD2),
    secondary: Color(0xFFFFB77A),
    onSecondary: Color(0xFF261100),
    secondaryContainer: Color(0xFF5B2800),
    onSecondaryContainer: Color(0xFFFFDBC5),
    tertiary: Color(0xFF6FE0A8),
    onTertiary: Color(0xFF102319),
    tertiaryContainer: Color(0xFF124C30),
    onTertiaryContainer: Color(0xFFC5F6D9),
    error: Color(0xFFFFB4AC),
    onError: Color(0xFF310604),
    errorContainer: Color(0xFF71100C),
    onErrorContainer: Color(0xFFFFDAD5),
    surface: Color(0xFF12100F),
    onSurface: Color(0xFFFFF9F4),
    onSurfaceVariant: Color(0xFFD8CBC4),
    outline: Color(0xFFA9958B),
    outlineVariant: Color(0xFF51443E),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFECE0DA),
    onInverseSurface: Color(0xFF231D1A),
    inversePrimary: Color(0xFF8F1D0D),
  );

  static const _lightSemanticColors = AppSemanticColors(
    accent: Color(0xFF7A3500),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFFFDBC5),
    onAccentContainer: Color(0xFF2A1000),
    success: Color(0xFF165C3A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFC5F6D9),
    onSuccessContainer: Color(0xFF063A22),
    warning: Color(0xFF7A4D00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFE0A3),
    onWarningContainer: Color(0xFF2B1900),
    info: Color(0xFF135A91),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFD2E9FF),
    onInfoContainer: Color(0xFF071E2F),
    dangerContainer: Color(0xFFFFDAD5),
    onDangerContainer: Color(0xFF3B0604),
    elevatedSurface: Color(0xFFFFFFFF),
    sunkenSurface: Color(0xFFF4ECE7),
    softOutline: Color(0xFFE6D7D0),
    heroSurface: Color(0xFF181412),
    heroOnSurface: Color(0xFFFFFFFF),
    shadow: Color(0x292C0C05),
  );

  static const _darkSemanticColors = AppSemanticColors(
    accent: Color(0xFFFFB77A),
    onAccent: Color(0xFF261100),
    accentContainer: Color(0xFF5B2800),
    onAccentContainer: Color(0xFFFFDBC5),
    success: Color(0xFF6FE0A8),
    onSuccess: Color(0xFF102319),
    successContainer: Color(0xFF124C30),
    onSuccessContainer: Color(0xFFC5F6D9),
    warning: Color(0xFFFFD18A),
    onWarning: Color(0xFF2A1800),
    warningContainer: Color(0xFF553500),
    onWarningContainer: Color(0xFFFFE0A3),
    info: Color(0xFF8DCCFF),
    onInfo: Color(0xFF071E2F),
    infoContainer: Color(0xFF0E426A),
    onInfoContainer: Color(0xFFD2E9FF),
    dangerContainer: Color(0xFF71100C),
    onDangerContainer: Color(0xFFFFDAD5),
    elevatedSurface: Color(0xFF211D1B),
    sunkenSurface: Color(0xFF181513),
    softOutline: Color(0xFF443934),
    heroSurface: Color(0xFF090807),
    heroOnSurface: Color(0xFFFFFFFF),
    shadow: Color(0x99000000),
  );

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scheme: _lightScheme,
    semanticColors: _lightSemanticColors,
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scheme: _darkScheme,
    semanticColors: _darkSemanticColors,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppSemanticColors semanticColors,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: defaultTargetPlatform == TargetPlatform.android
          ? InkSparkle.splashFactory
          : InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _PeriPageTransitionsBuilder(),
          TargetPlatform.iOS: _PeriPageTransitionsBuilder(),
          TargetPlatform.macOS: _PeriPageTransitionsBuilder(),
          TargetPlatform.windows: _PeriPageTransitionsBuilder(),
          TargetPlatform.linux: _PeriPageTransitionsBuilder(),
        },
      ),
      extensions: [semanticColors],
    );

    final textTheme = _textTheme(base.textTheme, scheme);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: semanticColors.softOutline),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      focusColor: scheme.primary.withValues(alpha: 0.16),
      hoverColor: scheme.primary.withValues(alpha: 0.08),
      highlightColor: scheme.primary.withValues(alpha: 0.08),
      dividerColor: semanticColors.softOutline,
      dividerTheme: DividerThemeData(
        color: semanticColors.softOutline,
        thickness: 1,
        space: 1,
      ),
      cardColor: semanticColors.elevatedSurface,
      cardTheme: CardThemeData(
        color: semanticColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semanticColors.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: semanticColors.softOutline),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: AppSpacing.xl,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: semanticColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: semanticColors.shadow,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: semanticColors.elevatedSurface,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: semanticColors.sunkenSurface,
        selectedColor: scheme.primary,
        disabledColor: semanticColors.sunkenSurface,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary,
        ),
        checkmarkColor: scheme.onPrimary,
        side: BorderSide(color: semanticColors.softOutline),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: semanticColors.sunkenSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 17,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: scheme.error,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(scheme, textTheme, semanticColors),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(scheme, textTheme, semanticColors),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.09),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 13),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.primary, width: 1.5),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.09),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.input),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          iconSize: const WidgetStatePropertyAll(22),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: scheme.outline, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : semanticColors.sunkenSurface;
        }),
        trackOutlineColor: WidgetStatePropertyAll(scheme.outline),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minTileHeight: 56,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: semanticColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: semanticColors.shadow,
        elevation: 18,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: BorderSide(color: semanticColors.softOutline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: semanticColors.elevatedSurface,
        modalBackgroundColor: semanticColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scheme.scrim.withValues(alpha: isDark ? 0.72 : 0.54),
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        dragHandleSize: const Size(44, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 8,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: semanticColors.sunkenSurface,
        circularTrackColor: semanticColors.sunkenSurface,
        linearMinHeight: 6,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(AppRadii.pill),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontSize: 36,
            height: 1.04,
            letterSpacing: -1.1,
            fontWeight: FontWeight.w800,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontSize: 32,
            height: 1.08,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w800,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontSize: 28,
            height: 1.1,
            letterSpacing: -0.55,
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: 27,
            height: 1.12,
            letterSpacing: -0.45,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 23,
            height: 1.16,
            letterSpacing: -0.25,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 21,
            height: 1.2,
            letterSpacing: -0.15,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 19,
            height: 1.22,
            letterSpacing: -0.12,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 16,
            height: 1.3,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            height: 1.3,
            letterSpacing: 0.05,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.05,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.48,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.42,
            letterSpacing: 0.12,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14,
            height: 1.2,
            letterSpacing: 0.12,
            fontWeight: FontWeight.w800,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 12,
            height: 1.2,
            letterSpacing: 0.18,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11,
            height: 1.2,
            letterSpacing: 0.25,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  static ButtonStyle _primaryButtonStyle(
    ColorScheme scheme,
    TextTheme textTheme,
    AppSemanticColors semanticColors,
  ) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return semanticColors.sunkenSurface;
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurfaceVariant;
        }
        return scheme.onPrimary;
      }),
      overlayColor: WidgetStatePropertyAll(
        scheme.onPrimary.withValues(alpha: 0.12),
      ),
      shadowColor: WidgetStatePropertyAll(semanticColors.shadow),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return 0;
        if (states.contains(WidgetState.disabled)) return 0;
        return 2;
      }),
      minimumSize: const WidgetStatePropertyAll(Size(48, 54)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PeriPageTransitionsBuilder extends PageTransitionsBuilder {
  const _PeriPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.72, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
