import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const ink = Color(0xFFFFFFFF);
    const canvas = Color(0xFF000000);
    const card = Color(0xFF050505);
    const muted = Color(0xFFB8B8B8);

    final textTheme = _textTheme(ink: ink, muted: muted);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: Brightness.dark,
      primary: Colors.white,
      secondary: const Color(0xFF5BB450),
      surface: card,
      error: const Color(0xFFC53B30),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      cardColor: card,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Color(0xFF3A3A3A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: const Color(0xFF0F0F0F),
        hintColor: muted,
        focusColor: Colors.white,
      ),
    );
  }

  static ThemeData light() {
    const ink = Color(0xFF141414);
    const canvas = Color(0xFFFFFFFF);
    const card = Color(0xFFFFFFFF);
    const muted = Color(0xFF6F6A62);

    final textTheme = _textTheme(ink: ink, muted: muted);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7A4A26),
      brightness: Brightness.light,
      primary: const Color(0xFF1F1A17),
      secondary: const Color(0xFF5BB450),
      surface: card,
      error: const Color(0xFFC53B30),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      cardColor: card,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F1A17),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Color(0xFFD2C6B7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: const Color(0xFFF6F6F3),
        hintColor: muted,
        focusColor: const Color(0xFF7A4A26),
      ),
    );
  }

  static TextTheme _textTheme({
    required Color ink,
    required Color muted,
  }) {
    return TextTheme(
      displaySmall: GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: ink,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: ink,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color hintColor,
    required Color focusColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.poppins(
        color: hintColor,
        fontSize: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color shellStart(BuildContext context) =>
      isDark(context) ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  static Color shellEnd(BuildContext context) =>
      isDark(context) ? const Color(0xFF070707) : const Color(0xFFFFFFFF);

  static Color cardBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF050505) : const Color(0xFFFFFFFF);

  static Color cardBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A2A2A) : const Color(0xFFE8E5DE);

  static Color actionSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B0B0B) : const Color(0xFFF8F7F3);

  static Color dockDivider(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F1F1F) : const Color(0xFFE3E0D8);

  static Color dockInactive(BuildContext context) =>
      isDark(context) ? const Color(0xFF101010) : const Color(0xFFFFFFFF);

  static Color dockActive(BuildContext context) =>
      isDark(context) ? const Color(0xFF181818) : const Color(0xFFF2F0EB);

  static Color primaryButton(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1F1A17);

  static Color primaryButtonForeground(BuildContext context) =>
      isDark(context) ? Colors.black : Colors.white;
}
