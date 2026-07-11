import 'package:flutter/material.dart';

class HomeEaseTheme {
  static const Color background = Color(0xFFF4EDE5);
  static const Color surface = Color(0xFFFFF8F0);
  static const Color card = Color(0xFFEEDFCB);
  static const Color cardDark = Color(0xFFE4C9AA);
  static const Color brand = Color(0xFF754B38);
  static const Color brandSoft = Color(0xFFB78C69);
  static const Color text = Color(0xFF31241E);
  static const Color muted = Color(0xFF857067);
  static const Color white = Colors.white;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.light,
        primary: brand,
        secondary: brandSoft,
        surface: surface,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: text,
          height: 1.1,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: text,
          height: 1.15,
        ),
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: text, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, color: muted, height: 1.45),
        bodySmall: const TextStyle(fontSize: 12, color: muted, height: 1.35),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: brand,
        contentTextStyle: TextStyle(color: white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F0E6),
        hintStyle: const TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
