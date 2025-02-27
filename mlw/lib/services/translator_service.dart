import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class TranslatorService {
  String? _apiKey;
  final String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';
  
  // 생성자에서 API 키 로드 시도
  TranslatorService() {
    _loadApiKey();
  }
  
  Future<void> _loadApiKey() async {
    try {
      // 서비스 계정 키 파일 로드
      final String jsonString = await rootBundle.loadString('assets/service-account-key.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // API 키 추출
      _apiKey = jsonData['api_key'] ?? '';
      print('Google API 키 로드 ${_apiKey != null && _apiKey!.isNotEmpty ? '성공' : '실패'}');
    } catch (e) {
      print('API 키 로드 오류: $e');
      _apiKey = '';
    }
  }
  
  // 메인 번역 함수
  Future<String> translate(String text, String targetLanguage, {String sourceLanguage = 'auto'}) async {
    if (text.isEmpty) return '';
    
    print('번역 요청: 텍스트=$text, 대상언어=$targetLanguage, 소스언어=$sourceLanguage');
    
    // API 키가 아직 로드되지 않았다면 로드
    if (_apiKey == null) {
      await _loadApiKey();
      print('API 키 로드 결과: ${_apiKey ?? "null"}');
    }
    
    // API 키가 없거나 비어있으면 오류 메시지 반환
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('Google Translate API 키가 설정되지 않았습니다.');
      return 'Sorry, translation is not supported at this moment. Please try again later.';
    }
    
    // Google API 시도
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        body: {
          'q': text,
          'target': _getLanguageCode(targetLanguage),
          'source': sourceLanguage == 'auto' ? '' : _getLanguageCode(sourceLanguage),
          'format': 'text',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['data']['translations'] as List;
        if (translations.isNotEmpty) {
          return translations[0]['translatedText'];
        }
      }
      
      print('번역 API 오류: ${response.statusCode} - ${response.body}');
      return 'Sorry, translation failed. Please try again later.';
    } catch (e) {
      print('번역 중 오류 발생: $e');
      return 'Sorry, an error occurred during translation. Please try again later.';
    }
  }
  
  String _getLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case '한국어':
        return 'ko';
      case '영어':
        return 'en';
      case '중국어':
      case '중국어(간체)':
        return 'zh-CN';
      case '중국어(번체)':
        return 'zh-TW';
      case '일본어':
        return 'ja';
      default:
        return language;
    }
  }
}

// 단일 번역 서비스 인스턴스
final translatorService = TranslatorService(); 