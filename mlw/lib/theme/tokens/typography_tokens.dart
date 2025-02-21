import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypographyTokens {
  static TextStyle getStyle(String path) {
    // path format: 'display.large', 'heading.h1', 'body.medium' 등
    final parts = path.split('.');
    if (parts.length != 2) {
      return GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );
    }

    final category = parts[0];
    final variant = parts[1];

    switch ('$category.$variant') {
      case 'heading.h1':
        return GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0,
        );
      case 'heading.h2':
        return GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0,
        );
      case 'body':
      case 'body.medium':
        return GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: 0,
        );
      case 'body.small':
        return GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.2,
          letterSpacing: 0,
        );
      case 'button.medium':
        return GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: 0,
        );
      case 'button.small':
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: 0,
        );
      default:
        return GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        );
    }
  }

  static TextStyle getButtonStyle({bool isSmall = false}) {
    return getStyle(isSmall ? 'button.small' : 'button.medium');
  }
} 