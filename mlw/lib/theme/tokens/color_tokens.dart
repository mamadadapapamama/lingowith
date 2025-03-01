import 'package:flutter/material.dart';

class ColorTokens {
  // Base Colors
  static const Map<int, Color> base = {
    0: Color(0xFFFFFFFF),
    200: Color(0xFFE5E5E5),
    400: Color(0xFFB2B2B2),
    500: Color(0xFF969696),
    600: Color(0xFF705F5F),
    800: Color(0xFF000000),
  };

  // Primary Colors
  static const Map<int, Color> primary = {
    25: Color(0xFFFFF9F1),
    50: Color(0xFFFFF0E8),
    100: Color(0xFFFFE1D0),
    200: Color(0xFFFFB48A),
    300: Color(0xFFFE975B),
    400: Color(0xFFFE6A15),
    500: Color(0xFFCB5511),
    600: Color(0xFF98400D),
    700: Color(0xFF662A08),
  };

  // Secondary Colors
  static const Map<int, Color> secondary = {
    25: Color(0xFFF1F3F3),
    100: Color(0xFFD3E0DD),
    200: Color(0xFF90B1AB),
    300: Color(0xFF649289),
    400: Color(0xFF226357),
    500: Color(0xFF1B4F46),
    600: Color(0xFF143B34),
    700: Color(0xFF0E2823),
  };

  // Tertiary Colors
  static const Map<int, Color> tertiary = {
    100: Color(0xFFFFF7D8),
    200: Color(0xFFFFEA9D),
    300: Color(0xFFFFE277),
    400: Color(0xFFFFD53C),
    500: Color(0xFFCCAA30),
    600: Color(0xFF998024),
    700: Color(0xFF665518),
  };

  // Semantic Colors
  static const Map<String, dynamic> semantic = {
    'text': {
      'body': Color(0xFF0E2823),
      'description':Color(0xFF0E2823),
      'heading': Color(0xFF0E2823),
      'primary': Color(0xFFFFFFFF),
      'secondary': Color(0xFFFFFFFF),
      'translation': Color(0xFF226357),
      'disabled': Color(0xFF705F5F),
      'success': Color(0xFF32543F),
    },
    'surface': {
      'background': Color(0xFFFFF9F1),
      'base': Color(0xFFFFFFFF),
      'button': {
        'primary': Color(0xFFFE6A15),
        'primary-hover': Color(0xFFCB5511),
        'secondary': Color(0xFF226357),
        'secondary-hover': Color(0xFF143B34),
        'disabled': Color(0xFFB2B2B2),
      }
    },
    'border': {
      'base': Color(0xFFFFE1D0),
      'success': Color(0xFF7ED29E),
      'base-2': Color(0xFFFFFFFF),
    },
  };

  static Color getColor(String path) {
    final parts = path.split('.');
    if (parts.length == 2) {
      final category = parts[0];
      final variant = parts[1];
      
      if (int.tryParse(variant) != null) {
        final shade = int.tryParse(variant) ?? 400;
        switch (category) {
          case 'primary':
            return primary[shade] ?? primary[400]!;
          case 'secondary':
            return secondary[shade] ?? secondary[400]!;
          case 'tertiary':
            return tertiary[shade] ?? tertiary[400]!;
          case 'base':
            return base[shade] ?? base[200]!;
        }
      }
      
      // semantic color with variant (e.g., 'text.body')
      return semantic[category]?[variant] ?? Colors.black;
    }
    
    return Colors.black;
  }
} 