import 'package:flutter/material.dart';

class HomeEaseTheme {
  // Clean Teal & Mint Trust Palette
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color card = Color(0xFFF1F5F9); // Slate 100
  static const Color cardDark = Color(0xFFE2E8F0); // Slate 200
  static const Color brand = Color(0xFF0F766E); // Deep Teal
  static const Color brandSoft = Color(0xFF14B8A6); // Mint / Aquamarine
  static const Color text = Color(0xFF0F172A); // Slate 900 (WCAG AAA)
  static const Color muted = Color(0xFF64748B); // Slate 500
  static const Color white = Colors.white;

  // Semantic aliases for consistency
  static const Color primary = brand;
  static const Color primaryDark = Color(0xFF115E59); // Teal 800
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 100 / Mint tint
  static const Color secondary = brandSoft;
  static const Color accentLight = Color(0xFFCCFBF1);
  static const Color textPrimary = text;
  static const Color textSecondary = muted;
  static const Color outline = cardDark;
  static const Color cardBackground = surface;

  // Semantic Status Colors
  static const Color statusVerified = Color(0xFF10B981); // Emerald 500
  static const Color statusAccepted = Color(0xFF10B981);
  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B); // Amber 500
  static const Color statusConflict = Color(0xFFEF4444); // Red 500
  static const Color statusCancelled = Color(0xFF64748B); // Slate 500
  static const Color statusInfo = Color(0xFF0284C7); // Sky 600
  static const Color starRating = Color(0xFFF59E0B); // Amber 500 curated star rating

  // Dark Theme Palette Tokens (Slate & Deep Teal Contrast)
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDarkSurface = Color(0xFF1E293B); // Slate 800
  static const Color outlineDark = Color(0xFF334155); // Slate 700
  static const Color textDark = Color(0xFFF8FAFC); // Slate 50 (WCAG AAA)
  static const Color mutedDark = Color(0xFF94A3B8); // Slate 400
  static const Color accentDark = Color(0xFF115E59); // Teal 800

  // Animation & Motion Constants
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveEase = Curves.easeInOut;

  // Box Shadows & Glows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mintGlow => [
    BoxShadow(
      color: brandSoft.withValues(alpha: 0.35),
      blurRadius: 14,
      spreadRadius: 1,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get brandGlow => [
    BoxShadow(
      color: brand.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

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
        error: statusConflict,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -0.6,
          height: 1.15,
        ),
        headlineMedium: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: text,
          letterSpacing: -0.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
          letterSpacing: -0.1,
        ),
        bodyLarge: const TextStyle(fontSize: 15, color: text, height: 1.5, letterSpacing: 0.1),
        bodyMedium: const TextStyle(fontSize: 14, color: muted, height: 1.45, letterSpacing: 0.1),
        bodySmall: const TextStyle(fontSize: 12, color: muted, height: 1.35, letterSpacing: 0.2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: brand,
        disabledColor: card,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: text),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: outline, width: 1),
      ),
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
        space: 20,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: brand,
        contentTextStyle: TextStyle(color: white, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brand,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: statusConflict),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.dark,
        primary: brandSoft,
        secondary: brand,
        surface: surfaceDark,
        error: statusConflict,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.6,
          height: 1.15,
        ),
        headlineMedium: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.3,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.1,
        ),
        bodyLarge: const TextStyle(fontSize: 15, color: textDark, height: 1.5, letterSpacing: 0.1),
        bodyMedium: const TextStyle(fontSize: 14, color: mutedDark, height: 1.45, letterSpacing: 0.1),
        bodySmall: const TextStyle(fontSize: 12, color: mutedDark, height: 1.35, letterSpacing: 0.2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: brandSoft,
        disabledColor: cardDarkSurface,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: outlineDark, width: 1),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineDark,
        thickness: 1,
        space: 20,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outlineDark),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: TextStyle(color: textDark, fontWeight: FontWeight.w600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: brandSoft,
        unselectedItemColor: mutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        hintStyle: const TextStyle(color: mutedDark, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandSoft, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: statusConflict),
        ),
      ),
    );
  }
}
