import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfigLoader {
  static const String _keyFilePath = 'assets/service-account-key.json';
  
  /// JSON 키 파일에서 Firebase 옵션을 로드합니다.
  static Future<FirebaseOptions> loadOptions() async {
    try {
      // 키 파일 읽기
      final String jsonString = await rootBundle.loadString(_keyFilePath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // 플랫폼별 옵션 생성
      return FirebaseOptions(
        apiKey: jsonData['apiKey'] ?? '',
        appId: jsonData['appId'] ?? '',
        messagingSenderId: jsonData['messagingSenderId'] ?? '',
        projectId: jsonData['projectId'] ?? '',
        authDomain: jsonData['authDomain'],
        storageBucket: jsonData['storageBucket'],
        // iOS 전용 옵션
        iosClientId: jsonData['iosClientId'],
        iosBundleId: jsonData['iosBundleId'],
        // Android 전용 옵션
        androidClientId: jsonData['androidClientId'],
      );
    } catch (e) {
      print('Firebase 설정 파일 로드 오류: $e');
      rethrow;
    }
  }
} 