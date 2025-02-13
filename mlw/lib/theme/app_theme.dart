import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';

class AppTheme {
  // 현재 사용중인 색상을 우선 정의
  static const colors = ColorTokens.colors;
  
  // Primary 색상 접근을 위한 헬퍼 메서드
  static Color getPrimaryColor(int strength) {
    return ColorTokens.primary[strength] ?? ColorTokens.primary[400]!;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: getPrimaryColor(400),
        background: colors['background']!,
        surface: colors['surface']!,
        error: colors['error']!,
      ),
      scaffoldBackgroundColor: colors['background'],
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors['text'],
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors['text'],
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors['text'],
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors['textSecondary'],
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colors['cardBorder']!,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: getPrimaryColor(400),
          foregroundColor: colors['surface'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: getPrimaryColor(700),
      ),
    );
  }
} 