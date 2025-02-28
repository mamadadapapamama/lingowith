import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

/// 앱 전체 테마 정의
class AppTheme {
  /// 라이트 테마 정의
  static final ThemeData lightTheme = ThemeData(
    // 기본 색상 설정
    primaryColor: ColorTokens.getColor('primary.500'),
    scaffoldBackgroundColor: ColorTokens.getColor('base.0'),
    
    // 앱바 테마
    appBarTheme: AppBarTheme(
      backgroundColor: ColorTokens.getColor('base.0'),
      foregroundColor: ColorTokens.getColor('text.heading'),
      elevation: 0,
      titleTextStyle: TypographyTokens.getStyle('heading.h4').copyWith(
        color: ColorTokens.getColor('text.heading'),
      ),
      iconTheme: IconThemeData(
        color: ColorTokens.getColor('text.heading'),
      ),
    ),
    
    // 텍스트 테마
    textTheme: TextTheme(
      // 제목 스타일
      displayLarge: TypographyTokens.getStyle('heading.h1').copyWith(
        color: ColorTokens.getColor('text.heading'),
      ),
      displayMedium: TypographyTokens.getStyle('heading.h2').copyWith(
        color: ColorTokens.getColor('text.heading'),
      ),
      displaySmall: TypographyTokens.getStyle('heading.h3').copyWith(
        color: ColorTokens.getColor('text.heading'),
      ),
      headlineMedium: TypographyTokens.getStyle('heading.h4').copyWith(
        color: ColorTokens.getColor('text.heading'),
      ),
      headlineSmall: TypographyTokens.getStyle('heading.h5').copyWith(
        color: ColorTokens.getColor('text.heading'),
      ),
      
      // 본문 스타일
      bodyLarge: TypographyTokens.getStyle('body.large').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
      bodyMedium: TypographyTokens.getStyle('body.medium').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
      bodySmall: TypographyTokens.getStyle('body.small').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
      
      // 버튼 스타일
      labelLarge: TypographyTokens.getStyle('button.large').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
      labelMedium: TypographyTokens.getStyle('button.medium').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
      labelSmall: TypographyTokens.getStyle('button.small').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
    ),
    
    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorTokens.getColor('primary.500'),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TypographyTokens.getStyle('button.medium'),
        elevation: 0,
      ),
    ),
    
    // 텍스트 버튼 테마
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorTokens.getColor('primary.500'),
        textStyle: TypographyTokens.getStyle('button.medium'),
      ),
    ),
    
    // 아웃라인 버튼 테마
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorTokens.getColor('primary.500'),
        side: BorderSide(color: ColorTokens.getColor('primary.500')),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TypographyTokens.getStyle('button.medium'),
      ),
    ),
    
    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorTokens.getColor('base.0'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ColorTokens.getColor('neutral.300')),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ColorTokens.getColor('neutral.300')),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ColorTokens.getColor('primary.500')),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ColorTokens.getColor('error.500')),
      ),
      labelStyle: TypographyTokens.getStyle('body.medium').copyWith(
        color: ColorTokens.getColor('text.body'),
      ),
      hintStyle: TypographyTokens.getStyle('body.medium').copyWith(
        color: ColorTokens.getColor('text.placeholder'),
      ),
    ),
    
    // 카드 테마
    cardTheme: CardTheme(
      color: ColorTokens.getColor('base.0'),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    
    // 체크박스 테마
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorTokens.getColor('primary.500');
        }
        return ColorTokens.getColor('neutral.300');
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    
    // 라디오 버튼 테마
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorTokens.getColor('primary.500');
        }
        return ColorTokens.getColor('neutral.300');
      }),
    ),
    
    // 스위치 테마
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorTokens.getColor('primary.500');
        }
        return ColorTokens.getColor('neutral.300');
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return ColorTokens.getColor('primary.200');
        }
        return ColorTokens.getColor('neutral.200');
      }),
    ),
    
    // 진행 표시기 테마
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: ColorTokens.getColor('primary.500'),
    ),
    
    // 컬러스킴
    colorScheme: ColorScheme.light(
      primary: ColorTokens.getColor('primary.500'),
      secondary: ColorTokens.getColor('secondary.500'),
      error: ColorTokens.getColor('error.500'),
      surface: ColorTokens.getColor('base.0'),
    ),
  );
} 