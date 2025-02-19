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
      // fontSize가 문자열인 경우 fontSizes 맵에서 해당하는 값을 찾음
      final fontSizes = _tokens!['fontSize'];
      return (fontSizes[fontSize] as num).toDouble();
    }
    return 16.0; // 기본값
  }

  static TextStyle getStyle(String styleName) {
    if (_tokens == null) {
      throw Exception('TypographyTokens not initialized. Call initialize() first.');
    }

    final style = _tokens!['styles'][styleName];
    if (style == null) {
      throw Exception('Style $styleName not found in typography tokens.');
    }

    final fontSize = _getFontSize(style['fontSize']);
    final fontFamily = _tokens!['fontFamily'][style['fontFamily']];
    final fontWeight = _tokens!['fontWeight'][style['fontWeight']];

    return GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.values[fontWeight ~/ 100],
      height: style['lineHeight'] / fontSize,
      letterSpacing: style['letterSpacing'].toDouble(),
    );
  }

  static TextStyle getButtonStyle({bool isSmall = false}) {
    if (_tokens == null) {
      throw Exception('TypographyTokens not initialized. Call initialize() first.');
    }

    final style = _tokens!['styles']['button'][isSmall ? 'small' : 'default'];
    final fontSize = _getFontSize(style['fontSize']);
    final fontFamily = _tokens!['fontFamily'][style['fontFamily']];
    final fontWeight = _tokens!['fontWeight'][style['fontWeight']];
    
    return GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.values[fontWeight ~/ 100],
      height: style['lineHeight'] / fontSize,
      letterSpacing: style['letterSpacing'].toDouble(),
    );
  }
} 