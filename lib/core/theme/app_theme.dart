import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Deep Indigo/Blue Aesthetic (Matched to Photo)
  static const Color background = Color(0xFF020617); // Deepest Night Blue
  static const Color surface = Color(0xFF0F172A); // Navy Surface
  static const Color surfaceHighlight = Color(0xFF1E293B); // Slate Surface

  // Light Theme Colors
  static const Color lightBackground = Color.fromARGB(255, 160, 142, 142);
  static const Color lightSurface = Color.fromARGB(
    255,
    115,
    115,
    116,
  ); // Light grey
  static const Color lightSurfaceHighlight = Color.fromARGB(
    255,
    111,
    118,
    134,
  ); // Lighter grey

  // Primary Colors (Blue/Indigo)
  static const Color primary = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryVariant = Color(0xFF60A5FA); // Sky Blue

  // Accent Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF0EA5E9); // Light Blue
  static const Color pink = Color(0xFFD946EF); // Fuchsia
  static const Color zenOrange = Color(0xFFFFA62B); // Original Orange

  // Legacy/Meter Aliases
  static const Color meterGreen = success;
  static const Color meterYellow = warning;
  static const Color meterRed = error;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Muted Slate
  static const Color lightTextPrimary = Colors.black;
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Gradients (Blue focused)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healingGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF3B82F6)], // Emerald to Blue
  );

  static const LinearGradient focusGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
  );

  static const LinearGradient energyGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Purple
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromARGB(255, 143, 119, 185),
      primaryColor: const Color.fromARGB(255, 52, 3, 3),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: pink,
        surface: lightSurface,
        error: error,
        onSurface: lightTextPrimary,
        onPrimary: Colors.white,
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: const TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: const TextStyle(color: lightTextPrimary),
        bodyMedium: const TextStyle(color: lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceHighlight,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        foregroundColor: lightTextPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: pink,
        surface: surface,
        error: error,
        onSurface: textPrimary,
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: const TextStyle(color: textPrimary),
        bodyMedium: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHighlight,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
    );
  }

  // Optional: Helper getters for theme detection
  static bool get isDarkMode => false; // You can change this logic
  static bool get isLightTheme => true; // You can change this logic
}
