import 'package:flutter/material.dart';

/// BlueMart App Theme - Material Design 3 with Glassmorphism & AnimatedGradient
class AppTheme {
  AppTheme._();

  // ---- Brand Colors ----
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryLighter = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFF3B82F6);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF1F5F9);

  // ---- Glassmorphism Shadows ----
  static List<BoxShadow> glassShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ---- Glassmorphism Card ----
  static BoxDecoration glassCardDecoration({Color? bgColor}) => BoxDecoration(
    color: bgColor ?? Colors.white.withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
  );

  // ---- AnimatedGradient Decoration ----
  static const BoxDecoration animatedGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primaryLight, primaryLighter, surface],
      stops: [0.0, 0.3, 0.5, 1.0],
    ),
  );

  static const BoxDecoration gradientTop = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFFF8FAFC)],
      stops: [0.0, 0.35, 0.35],
    ),
  );

  // ---- Material Theme ----
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primaryLight,
      tertiary: primaryLighter,
      surface: surface,
      error: error,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: surface,

    // AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: textHint,
    ),

    // Card
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: divider.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFF1F5F9),
      thickness: 1,
    ),

    // Chip
    chipTheme: ChipThemeData(
      selectedColor: primary,
      labelStyle: const TextStyle(fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
