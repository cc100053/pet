import 'package:flutter/material.dart';

import '../ui/status_bar_style.dart';

class AppTheme {
  // "Mori" palette: soft leaf greens on warm paper, warm-brown outlines
  // instead of black. See memory-bank/ui-ux-guidelines.md.
  static const Color primaryColor = leaf;
  static const Color secondaryColor = Color(0xFFFFB36B); // Warm Orange Accent
  static const Color surfaceColor = Color(0xFFFFFDF7);
  static const Color backgroundColor = paper;

  static const Color paper = Color(0xFFFBF6EA);
  static const Color ink = Color(0xFF5A4636); // outlines, hard shadows
  static const Color leaf = Color(0xFF6DBE8C);
  // Filled buttons with white text: 3.15:1 on white, OK for large bold labels.
  static const Color leafStrong = Color(0xFF47A26E);
  static const Color leafDeep = Color(0xFF2F7650); // press shadow
  static const Color sky = Color(0xFFA8D8EA);
  static const Color sakura = Color(0xFFF5B8C4);
  static const Color kinako = Color(0xFFF3DDAA);
  static const Color wood = Color(0xFFC79A6B);
  static const Color gold = Color(0xFFF0B83C); // rarity/rewards only
  static const Color softLine = Color(0xFFEADBC3);
  static const Color errorColor = Color(0xFFFF4D4D);
  static const Color successColor = Color(0xFF00C853);

  // Text Colors
  static const Color textPrimary = Color(0xFF2F2A23); // Ink / Dark Brown
  static const Color textSecondary = Color(0xFF7A6F66); // Muted Brown

  // Chat Bubble Colors
  static const Color chatBubbleMe = Color(0xFFE6F4F1); // Light Teal
  static const Color chatBubbleOther = Colors.white;

  static ThemeData get lightTheme {
    final baseTextTheme = Typography.material2021().black;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Use a local Material text theme so app startup never depends on a
      // runtime font fetch.
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textPrimary),
        labelLarge: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: softLine, width: 2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: AppStatusBarStyles.light,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: softLine, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }

  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [leaf, Color(0xFF8FD3A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB36B), Color(0xFFF79B5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
