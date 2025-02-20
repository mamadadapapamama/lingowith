import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypographyTokens {
  static final Map<String, TextStyle> _styles = {
    'displayLarge': GoogleFonts.poppins(
      fontSize: 57,
      fontWeight: FontWeight.normal,
    ),
    'displayMedium': GoogleFonts.poppins(
      fontSize: 45,
      fontWeight: FontWeight.normal,
    ),
    'displaySmall': GoogleFonts.poppins(
      fontSize: 36,
      fontWeight: FontWeight.normal,
    ),
    'headlineLarge': GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.normal,
    ),
    'headlineMedium': GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.normal,
    ),
    'headlineSmall': GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.normal,
    ),
    'titleLarge': GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.normal,
    ),
    'titleMedium': GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    'titleSmall': GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    'bodyLarge': GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    'bodyMedium': GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    'bodySmall': GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
    'labelLarge': GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    'labelMedium': GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    'labelSmall': GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  };

  static TextStyle getStyle(String style) {
    return _styles[style] ?? const TextStyle();
  }
}