import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/translate/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CloudTranslationService {
  static const _serviceAccountKeyPath = 'assets/service-account-key.json';
  static const _projectId = 'mlw-translation'; // 실제 프로젝트 ID로 변경
  
  Future<String> translate(String text, String sourceLanguage, String targetLanguage) async {
    try {
      // 서비스 계정 키 로드
      final serviceAccountJson = await rootBundle.loadString(_serviceAccountKeyPath);
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      
      // 인증 클라이언트 생성
      final scopes = [TranslateApi.cloudTranslationScope];
      final client = await clientViaServiceAccount(serviceAccountCredentials, scopes);
      
      // Translation API 인스턴스 생성
      final translateApi = TranslateApi(client);
      
      // API 요청 생성
      final response = await translateApi.projects.translateText(
        TranslateTextRequest(
          contents: [text],
          sourceLanguageCode: sourceLanguage,
          targetLanguageCode: targetLanguage,
        ),
        'projects/$_projectId', // parent 매개변수 제거
      );
      
      // 결과 처리
      final translation = response.translations?.first.translatedText ?? text;
      
      // 클라이언트 종료
      client.close();
      
      return translation;
    } catch (e) {
      throw Exception('텍스트를 번역하는 중 오류가 발생했습니다: $e');
    }
  }
} 