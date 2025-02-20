import 'package:flutter/material.dart';

class ColorTokens {
  static final Map<String, Map<String, Color>> semantic = {
    'surface': {
      'background': const Color(0xFFF5F5F5),
      'card': Colors.white,
      'elevated': Colors.white,
    },
    'text': {
      'primary': Colors.black87,
      'secondary': Colors.black54,
      'disabled': Colors.black38,
    },
    'border': {
      'default': Colors.black12,
      'focused': Colors.blue,
    },
  };

  static Color getColor(String path) {
    final parts = path.split('.');
    if (parts.length != 2) return Colors.black;

    final category = parts[0];
    final variant = parts[1];

    return semantic[category]?[variant] ?? Colors.black;
  }
} 