import 'package:flutter/material.dart';

class ColorTokens {
  // Primary Colors (700 scale)
  static const Map<int, Color> primary = {
    100: Color(0xFFE6F4E6),  // 가장 연한 녹색
    200: Color(0xFFB3E0B3),  // 연한 녹색
    300: Color(0xFF80CC80),  // 중간 연한 녹색
    400: Color(0xFF7CF47C),  // 기본 녹색 (현재 neonGreen)
    500: Color(0xFF4DB84D),  // 진한 녹색
    600: Color(0xFF2E8B2E),  // 더 진한 녹색
    700: Color(0xFF214132),  // 가장 진한 녹색 (현재 deepGreen)
  };

  // 실제 사용되는 의미별 색상
  static const colors = {
    'background': Color(0xFFF9FFFB),
    'surface': Color(0xFFFFFFFF),
    'text': Color(0xFF214132),
    'textSecondary': Color(0xFF757575),
    'disabled': Color(0xFFE0E0E0),
    'cardBorder': Color(0xFF7CF47C),  // neonGreen
    'error': Color(0xFFE53935),
    'success': Color(0xFF4CAF50),
    'warning': Color(0xFFFFC107),
  };
} 