import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF3157FF);
  static const primaryLight = Color(0xFF7690FF);
  static const primaryDark = Color(0xFF1737C7);
  static const secondary = Color(0xFFFF4D8D);
  static const secondaryLight = Color(0xFFFF91B8);
  static const accent = secondary;

  static const black = Color(0xFF111217);
  static const offBlack = black;
  static const charcoal = Color(0xFF22242C);
  static const darkGray = Color(0xFF393C47);
  static const midGray = Color(0xFF70737E);
  static const lightGray = Color(0xFFA7A9B2);
  static const paleGray = Color(0xFFE7E7E4);
  static const offWhite = Color(0xFFF7F7F4);
  static const white = Color(0xFFFFFFFF);
  static const lavender = Color(0xFFEEF1FF);
  static const blush = Color(0xFFFFEEF4);
  static const mint = Color(0xFFE9F8F0);

  // Existing names retained so feature code stays small and consistent.
  static const primaryNavy = black;
  static const primaryNavyLight = charcoal;
  static const accentCoral = secondary;
  static const accentCoralLight = secondaryLight;
  static const surfaceWhite = offWhite;
  static const cardWhite = white;
  static const textPrimary = black;
  static const textSecondary = midGray;
  static const borderLight = paleGray;
  static const successGreen = Color(0xFF23A66F);
  static const errorRed = Color(0xFFE8424E);

  static const radiusSmall = 10.0;
  static const radiusMedium = 16.0;
  static const radiusLarge = 22.0;
  static const radiusXL = 30.0;
  static const radiusPill = 99.0;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: black.withValues(alpha: 0.045),
      blurRadius: 18,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: black.withValues(alpha: 0.09),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];

  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: primary,
      onPrimary: white,
      secondary: secondary,
      onSecondary: white,
      surface: white,
      onSurface: black,
      error: errorRed,
      outline: paleGray,
    );
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        height: 1.02,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
      ),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: offWhite,
      colorScheme: scheme,
      textTheme: textTheme.apply(bodyColor: black, displayColor: black),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: offWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: black),
      ),
      cardTheme: CardThemeData(
        color: white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: paleGray),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: black,
          side: const BorderSide(color: paleGray),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: paleGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: paleGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed),
        ),
        hintStyle: const TextStyle(color: lightGray),
        labelStyle: const TextStyle(color: midGray),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: black,
        unselectedLabelColor: midGray,
        indicatorColor: primary,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: white,
        selectedColor: black,
        side: const BorderSide(color: paleGray),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: black,
        contentTextStyle: const TextStyle(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: lavender,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? black : midGray,
          ),
        ),
      ),
    );
  }
}
