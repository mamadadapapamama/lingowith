import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypographyTokens {
  static Map<String, dynamic>? _tokens;
  
  static Future<void> initialize() async {
    final String jsonString = await rootBundle.loadString('assets/design_tokens/typography.json');
    _tokens = json.decode(jsonString);
  }

  static double _getFontSize(dynamic fontSize) {
    if (fontSize is num) return fontSize.toDouble();
    if (fontSize is String) {
      final fontSizes = _tokens!['fontSize'];
      return (fontSizes[fontSize] as num).toDouble();
    }
    return 16.0; // 기본값
  }

  static TextStyle getStyle(String path) {
    if (_tokens == null) {
      throw Exception('TypographyTokens not initialized. Call initialize() first.');
    }

    // path format: 'display.large', 'heading.h1', 'body.medium' 등
    final parts = path.split('.');
    if (parts.length != 2) {
      throw Exception('Invalid style path: $path. Format should be "category.variant"');
    }

    final category = parts[0];
    final variant = parts[1];

    final style = _tokens!['styles'][category]?[variant];
    if (style == null) {
      throw Exception('Style $path not found in typography tokens.');
    }

    final fontSize = _getFontSize(style['fontSize']);
    final fontFamily = _tokens!['fontFamily'][style['fontFamily']];
    final fontWeight = _tokens!['fontWeight'][style['fontWeight']];
    final lineHeight = style['lineHeight'];
    final letterSpacing = style['letterSpacing'].toDouble();

    return GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.values[fontWeight ~/ 100],
      height: lineHeight / fontSize,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle getButtonStyle({bool isSmall = false}) {
    final variant = isSmall ? 'small' : 'medium';
    return getStyle('button.$variant');
  }
} 