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
        seedColor: ColorTokens.primary[400] ?? Colors.green,
        background: Colors.white,
        surface: Colors.white,
        error: Colors.red,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorTokens.semantic['text']?['body'] ?? Colors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ColorTokens.semantic['text']?['body'] ?? Colors.black,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ColorTokens.semantic['text']?['body'] ?? Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ColorTokens.semantic['text']?['body'] ?? Colors.black87,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: ColorTokens.primary[100] ?? Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.primary[400] ?? Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: ColorTokens.primary[700] ?? Colors.green.shade700,
      ),
    );
  }
} 