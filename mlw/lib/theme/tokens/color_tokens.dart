import 'package:flutter/material.dart';

class ColorTokens {
  // Base colors
  static const Map<int, Color> base = {
    0: Color(0xFFFFFFFF),
    200: Color(0xFFE5E5E5),
    400: Color(0xFFB2B2B2),
    600: Color(0xFF705F5F),
    800: Color(0xFF000000),
  };

  // Primary colors
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

  // Secondary colors
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

  // Semantic colors
  static const Map<String, Map<String, Color>> semantic = {
    'text': {
      'body': Color(0xFF0E2823),
      'heading': Color(0xFF0E2823),
      'primary': Color(0xFFFFFFFF),
      'secondary': Color(0xFFFFFFFF),
      'disabled': Color(0xFF705F5F),
      'success': Color(0xFF32543F),
    },
    'surface': {
      'page': Color(0xFFFFF9F1),
      'base': Color(0xFFFFFFFF),
      'button-primary': Color(0xFFFE6A15),
      'button-primary-hover': Color(0xFFFE975B),
      'button-primary-on': Color(0xFFCB5511),
      'disabled': Color(0xFFE5E5E5),
    },
    'border': {
      'base': Color(0xFFFFE1D0),
      'success': Color(0xFF7ED29E),
    },
  };

  // Common colors
  static const Map<String, Color> colors = {
    'background': Color(0xFFF9FFFB),
    'surface': Color(0xFFFFFFFF),
    'text': Color(0xFF0E2823),
    'textSecondary': Color(0xFF705F5F),
  };
} 