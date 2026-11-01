import 'package:flutter/material.dart';

class AppTheme {
  // NOTE: sampled by eye from JEAP_Mobile_Figma_Ready_1.png, not extracted
  // programmatically — nudge these if you have exact hex values from Figma.
  static const Color jeapPurple = Color(0xFF4F46E5);
  static const Color jeapDarkPurple = Color(0xFF3730A3);
  static const Color backgroundColor = Color(0xFFF7F7FB);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color priceRed = Color(0xFFE53935);
  static const Color statusGreen = Color(0xFF2E7D32);
  static const Color inputFill = Color(0xFFF3F4F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: jeapPurple,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: jeapPurple,
        primary: jeapPurple,
        secondary: jeapDarkPurple,
        surface: cardColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: jeapPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: jeapPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: jeapPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }

  // 12px "buyer" corner radius used across cards/buttons in the Figma —
  // distinct from the older 4px rider-console radius above.
  static const double buyerRadius = 12;
}
