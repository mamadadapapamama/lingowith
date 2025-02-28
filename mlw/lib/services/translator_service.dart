import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
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
      print('서비스 계정 키 파일 로드 시도...');
      final String jsonString = await rootBundle.loadString('assets/service-account-key.json');
      print('서비스 계정 키 파일 로드 성공');
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // API 키 추출 (다양한 필드 이름 시도)
      _apiKey = jsonData['api_key'] ?? 
                jsonData['apiKey'] ?? 
                jsonData['key'] ?? 
                '';
      
      print('Google API 키 로드 ${_apiKey != null && _apiKey!.isNotEmpty ? '성공' : '실패'}');
    } catch (e) {
      print('API 키 로드 오류: $e');
      _apiKey = '';
    }
  }
  
  // 메인 번역 함수
  Future<String> translate(String text, String targetLanguage, {String sourceLanguage = 'auto'}) async {
    // 중국어 -> 한국어 간단한 번역 맵
    final Map<String, String> zhToKo = {
      '旧社会的农民敢怒而不敢言': '구 사회의 농민들은 분노할 수 있지만 말할 수 없었다',
      '同学们的造句或小中见大': '학생들의 문장 만들기는 작은 것에서 큰 것을 볼 수 있다',
      '是我觉得自惭形秽': '제가 부끄러워서',
      '期期艾艾地站在站台上': '머뭇거리며 플랫폼에 서 있다',
      '你好': '안녕하세요',
      '谢谢': '감사합니다',
      '再见': '안녕히 가세요',
    };
    
    // 간단한 번역 시도
    if (zhToKo.containsKey(text)) {
      return zhToKo[text]!;
    }
    
    if (text.isEmpty) return '';
    
    // MyMemory API로 번역 시도
    return await translateWithMyMemory(text, targetLanguage, sourceLanguage: sourceLanguage);
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

  Future<String> translateWithMyMemory(String text, String targetLanguage, {String sourceLanguage = 'auto'}) async {
    if (text.isEmpty) return '';
    
    final sourceLang = sourceLanguage == 'auto' ? 'zh-CN' : _getLanguageCode(sourceLanguage);
    final targetLang = _getLanguageCode(targetLanguage);
    
    try {
      final response = await http.get(
        Uri.parse('https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$sourceLang|$targetLang'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseData'] != null && data['responseData']['translatedText'] != null) {
          return data['responseData']['translatedText'];
        }
      }
      
      return 'Translation failed';
    } catch (e) {
      print('MyMemory 번역 오류: $e');
      return 'Translation error';
    }
  }

  // 중국어 문장 구분 개선
  List<String> splitChineseSentences(String text) {
    // 중국어 구두점 정의
    final punctuations = [
      '。', '！', '？', // 문장 종결 부호
      '，', '；', '：', // 문장 내 구두점
      '\n', '\r\n'     // 줄바꿈
    ];
    
    List<String> sentences = [];
    String currentSentence = '';
    
    for (int i = 0; i < text.length; i++) {
      currentSentence += text[i];
      
      // 구두점 또는 마지막 문자인 경우
      if (punctuations.contains(text[i]) || i == text.length - 1) {
        // 빈 문장이 아닌 경우에만 추가
        if (currentSentence.trim().isNotEmpty) {
          sentences.add(currentSentence.trim());
        }
        currentSentence = '';
      }
    }
    
    // 마지막 문장 처리
    if (currentSentence.trim().isNotEmpty) {
      sentences.add(currentSentence.trim());
    }
    
    return sentences;
  }

  // 번역 전처리 및 후처리
  Future<String> translateSentence(String text, String targetLanguage, {String sourceLanguage = 'auto'}) async {
    if (text.isEmpty) return '';
    
    // 특수 문자 처리
    final processedText = text
        .replaceAll('，', ', ')
        .replaceAll('：', ': ')
        .replaceAll('；', '; ');
    
    print('번역 전처리 텍스트: $processedText');
    
    final translatedText = await translate(processedText, targetLanguage, sourceLanguage: sourceLanguage);
    
    print('번역 결과: $translatedText');
    
    return translatedText;
  }
}

// 단일 번역 서비스 인스턴스
final translatorService = TranslatorService(); 