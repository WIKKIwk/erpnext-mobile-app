import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const seed = Color(0xFF8A7650);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFDBCEA5),
      onPrimary: const Color(0xFF2D2616),
      primaryContainer: const Color(0xFF8A7650),
      onPrimaryContainer: const Color(0xFFF7F2E1),
      secondary: const Color(0xFF8E977D),
      onSecondary: const Color(0xFF1E2418),
      secondaryContainer: const Color(0xFF4B5341),
      onSecondaryContainer: const Color(0xFFE8ECD9),
      tertiary: const Color(0xFFB79D72),
      onTertiary: const Color(0xFF21180C),
      tertiaryContainer: const Color(0xFF6A5737),
      onTertiaryContainer: const Color(0xFFF5E8CF),
      surface: const Color(0xFF171510),
      onSurface: const Color(0xFFECE7D1),
      surfaceDim: const Color(0xFF12100C),
      surfaceBright: const Color(0xFF343027),
      surfaceContainerLowest: const Color(0xFF0F0D09),
      surfaceContainerLow: const Color(0xFF211D16),
      surfaceContainer: const Color(0xFF28231B),
      surfaceContainerHigh: const Color(0xFF302A21),
      surfaceContainerHighest: const Color(0xFF3A3328),
      outline: const Color(0xFF9C9276),
      outlineVariant: const Color(0xFF5C5342),
    );
    final textTheme = _textTheme(
      base: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      ink: colorScheme.onSurface,
      muted: colorScheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerLow,
      dividerColor: colorScheme.outlineVariant,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      pageTransitionsTheme: _pageTransitionsTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.bodyMedium!,
        secondaryLabelStyle: textTheme.bodyMedium!.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: colorScheme.surfaceContainerHigh,
        hintColor: colorScheme.onSurfaceVariant,
        focusColor: colorScheme.primary,
        enabledBorderColor: colorScheme.outlineVariant,
        textColor: colorScheme.onSurface,
      ),
    );
  }

  static ThemeData light() {
    const seed = Color(0xFF8A7650);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF8A7650),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFDBCEA5),
      onPrimaryContainer: const Color(0xFF332A18),
      secondary: const Color(0xFF8E977D),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFDCE3CB),
      onSecondaryContainer: const Color(0xFF2C3323),
      tertiary: const Color(0xFFB79D72),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFF0E2C8),
      onTertiaryContainer: const Color(0xFF3E2F18),
      surface: const Color(0xFFECE7D1),
      onSurface: const Color(0xFF262117),
      surfaceDim: const Color(0xFFD8D0B4),
      surfaceBright: const Color(0xFFFBF8EE),
      surfaceContainerLowest: const Color(0xFFFFFCF5),
      surfaceContainerLow: const Color(0xFFF4EFDD),
      surfaceContainer: const Color(0xFFEEE7D0),
      surfaceContainerHigh: const Color(0xFFE7DFC5),
      surfaceContainerHighest: const Color(0xFFDBCEA5),
      outline: const Color(0xFF8F8468),
      outlineVariant: const Color(0xFFC8BEA2),
    );
    final textTheme = _textTheme(
      base: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      ink: colorScheme.onSurface,
      muted: colorScheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerLow,
      dividerColor: colorScheme.outlineVariant,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      pageTransitionsTheme: _pageTransitionsTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.bodyMedium!,
        secondaryLabelStyle: textTheme.bodyMedium!.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: colorScheme.surfaceContainerHighest,
        hintColor: colorScheme.onSurfaceVariant,
        focusColor: colorScheme.primary,
        enabledBorderColor: colorScheme.outlineVariant,
        textColor: colorScheme.onSurface,
      ),
    );
  }

  static TextTheme _textTheme({
    required TextTheme base,
    required Color ink,
    required Color muted,
  }) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: ink,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: ink,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color hintColor,
    required Color focusColor,
    required Color enabledBorderColor,
    required Color textColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      labelStyle: GoogleFonts.roboto(
        color: hintColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.roboto(
        color: hintColor,
        fontSize: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: enabledBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: enabledBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focusColor, width: 1.6),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      prefixIconColor: textColor,
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color shellStart(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color shellEnd(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color actionSurface(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  static Color dockDivider(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color dockInactive(BuildContext context) => Colors.transparent;

  static Color dockActive(BuildContext context) =>
      Theme.of(context).colorScheme.secondaryContainer;

  static Color primaryButton(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color primaryButtonForeground(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  static PageTransitionsTheme _pageTransitionsTheme() {
    const builder = _FadeOnlyPageTransitionsBuilder();
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: builder,
        TargetPlatform.iOS: builder,
        TargetPlatform.linux: builder,
        TargetPlatform.macOS: builder,
        TargetPlatform.windows: builder,
        TargetPlatform.fuchsia: builder,
      },
    );
  }
}

class _FadeOnlyPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeOnlyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Easing.standardDecelerate,
        reverseCurve: Easing.standardAccelerate,
      ),
      child: child,
    );
  }
}
