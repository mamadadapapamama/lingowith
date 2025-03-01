import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class TranslatorService {
  final String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';
  String? _apiKey;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // API 키 로드
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final keyData = json.decode(keyJson);
      _apiKey = keyData['api_key'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('API 키를 찾을 수 없습니다');
      }
      
      print('TranslatorService 초기화 성공');
      _initialized = true;
    } catch (e) {
      print('TranslatorService 초기화 실패: $e');
      throw Exception('번역 서비스 초기화 중 오류가 발생했습니다: $e');
    }
  }

  Future<String> translate(String text, {String from = 'zh', String to = 'ko'}) async {
    if (text.isEmpty) return '';
    
    if (!_initialized) {
      await initialize();
    }
    
    try {
      print('번역 시작: ${text.substring(0, text.length > 20 ? 20 : text.length)}...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': from,
          'target': to,
          'format': 'text',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['data']['translations'] as List;
        final translatedText = translations.first['translatedText'] as String;
        
        print('번역 완료: ${translatedText.substring(0, translatedText.length > 20 ? 20 : translatedText.length)}...');
        return translatedText;
      } else {
        print('번역 API 오류: ${response.statusCode}, ${response.body}');
        throw Exception('번역 API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('번역 오류: $e');
      // 오류 발생 시 원본 텍스트 반환
      return text;
    }
  }

  Future<String> translateText(String text, {String from = 'zh', String to = 'ko'}) async {
    if (text.isEmpty) return '';
    
    try {
      // 텍스트를 줄 단위로 분리
      final lines = text.split('\n');
      
      // 각 줄을 번역
      final translatedLines = await Future.wait(
        lines.map((line) => translate(line, from: from, to: to))
      );
      
      // 번역된 줄을 다시 합침
      return translatedLines.join('\n');
    } catch (e) {
      print('텍스트 번역 오류: $e');
      return text;
    }
  }
}

final translatorService = TranslatorService();