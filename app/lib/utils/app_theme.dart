import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Palette: Black + White + Blue Primary + Pink Secondary ──
  static const Color primary = Color(0xFF006DFD);         // brand blue
  static const Color primaryLight = Color(0xFF4D9BFF);    // lighter blue
  static const Color primaryDark = Color(0xFF0055CC);     // darker blue
  static const Color secondary = Color(0xFFF5378C);       // brand pink
  static const Color secondaryLight = Color(0xFFFF6EAD);  // lighter pink
  static const Color accent = secondary;                  // alias

  // Keep old names as aliases for backward compatibility with existing screens
  static const Color primaryNavy = Color(0xFF0A0A0A);     // near-black
  static const Color primaryNavyLight = Color(0xFF1A1A1A);
  static const Color accentCoral = secondary;             // map old coral → pink
  static const Color accentCoralLight = secondaryLight;

  static const Color black = Color(0xFF000000);
  static const Color offBlack = Color(0xFF0A0A0A);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color midGray = Color(0xFF6B6B6B);
  static const Color lightGray = Color(0xFFB0B0B0);
  static const Color paleGray = Color(0xFFE5E5E5);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  static const Color surfaceWhite = offWhite;
  static const Color cardWhite = white;
  static const Color textPrimary = offBlack;
  static const Color textSecondary = midGray;
  static const Color borderLight = paleGray;
  static const Color successGreen = Color(0xFF34C759);
  static const Color errorRed = Color(0xFFFF3B30);

  // ── Radii ──
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 20;
  static const double radiusPill = 50;

  // ── Shadows ──
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── ThemeData ──
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: white,
      primaryColor: primary,
      fontFamily: '.SF Pro Display',
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: offBlack,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: offBlack,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: offBlack),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: paleGray, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: offWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: lightGray,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: midGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: lightGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
