import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VitalSenseTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF0EA5E9);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertAmber = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0A0F1E);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1A2235);
  static const Color darkCardElevated = Color(0xFF1F2A40);
  static const Color darkBorder = Color(0xFF2D3748);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF0F4FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryGreen,
      tertiary: accentPurple,
      error: alertRed,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16, color: Color(0xFFCBD5E1),
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14, color: Color(0xFF94A3B8),
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryGreen,
      tertiary: accentPurple,
      error: alertRed,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF0F172A),
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFF0F172A),
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F172A),
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16, color: Color(0xFF334155),
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14, color: Color(0xFF64748B),
      ),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );

  // Vital Status Colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical': return alertRed;
      case 'warning': return alertAmber;
      case 'normal': return primaryGreen;
      case 'low': return accentPurple;
      default: return primaryBlue;
    }
  }

  // PHI Score Color
  static Color getPHIColor(double score) {
    if (score >= 80) return primaryGreen;
    if (score >= 60) return alertAmber;
    if (score >= 40) return const Color(0xFFFF6B35);
    return alertRed;
  }
}
