import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class AppConstants {
  // API 키 로드 메서드
  static Future<String> loadGoogleApiKey() async {
    try {
      // 서비스 계정 키 파일 로드
      final String jsonString = await rootBundle.loadString('assets/service-account-key.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // API 키 추출 (서비스 계정 키 구조에 따라 다를 수 있음)
      return jsonData['private_key'] ?? jsonData['key'] ?? '';
    } catch (e) {
      print('API 키 로드 오류: $e');
      return '';
    }
  }
  
  // 기타 상수...
} 