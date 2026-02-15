import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system — expressive headers, readable body, roast emphasis.
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      // Display — for roast text, hero moments
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),

      // Headlines
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),

      // Titles
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),

      // Body
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: const Color(0xFF9CA3AF),
      ),

      // Labels
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Special roast text style — dramatic, large, emotional.
  static TextStyle get roastText => GoogleFonts.spaceGrotesk(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.5,
    color: const Color(0xFFF1F1F5),
  );

  /// Accent text for emphasis.
  static TextStyle get accentText => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF8B5CF6),
  );
}
