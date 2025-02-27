import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 캐시 항목 클래스
class _CacheEntry {
  final String translation;
  final DateTime timestamp;
  
  _CacheEntry({
    required this.translation,
    required this.timestamp,
  });
  
  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      translation: json['translation'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'translation': translation,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TranslationCache {
  static final Map<String, _CacheEntry> _memoryCache = {};
  static const String _cacheKey = 'translation_cache';
  
  // 캐시에서 번역 가져오기
  static Future<String?> getTranslation(String text, String from, String to) async {
    final cacheKey = '$text|$from|$to';
    
    // 메모리 캐시 확인
    if (_memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      
      // 캐시 유효성 검사 (24시간)
      if (DateTime.now().difference(entry.timestamp).inHours < 24) {
        return entry.translation;
      } else {
        _memoryCache.remove(cacheKey);
      }
    }
    
    // 디스크 캐시 확인
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson != null) {
        final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
        
        if (cache.containsKey(cacheKey)) {
          final entry = _CacheEntry.fromJson(jsonDecode(cache[cacheKey]));
          
          // 캐시 유효성 검사 (24시간)
          if (DateTime.now().difference(entry.timestamp).inHours < 24) {
            // 메모리 캐시에 추가
            _memoryCache[cacheKey] = entry;
            return entry.translation;
          }
        }
      }
    } catch (e) {
      print('캐시 로드 오류: $e');
    }
    
    return null;
  }
  
  // 번역 결과 캐시에 저장
  static Future<void> cacheTranslation(String text, String from, String to, String translation) async {
    final cacheKey = '$text|$from|$to';
    final entry = _CacheEntry(
      translation: translation,
      timestamp: DateTime.now(),
    );
    
    // 메모리 캐시에 저장
    _memoryCache[cacheKey] = entry;
    
    // 디스크 캐시에 저장
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      final Map<String, dynamic> cache = cacheJson != null
          ? jsonDecode(cacheJson) as Map<String, dynamic>
          : {};
      
      cache[cacheKey] = jsonEncode(entry.toJson());
      
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      print('캐시 저장 오류: $e');
    }
  }
  
  // 캐시 정리
  static Future<void> clearCache() async {
    _memoryCache.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('캐시 정리 오류: $e');
    }
  }
}

class TranslatorService {
  final http.Client _httpClient;
  
  TranslatorService({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();
  
  // 텍스트 번역
  Future<String> translate(String text, String sourceLanguage, String targetLanguage) async {
    // 실제 구현은 외부 번역 API를 사용할 수 있습니다
    // 여기서는 간단한 예시로 구현
    
    // 중국어 -> 한국어 간단한 사전
    final Map<String, String> zhToKo = {
      '你好': '안녕하세요',
      '谢谢': '감사합니다',
      '再见': '안녕히 가세요',
      // 더 많은 번역 추가 가능
    };
    
    // 한국어 -> 중국어 간단한 사전
    final Map<String, String> koToZh = {
      '안녕하세요': '你好',
      '감사합니다': '谢谢',
      '안녕히 가세요': '再见',
      // 더 많은 번역 추가 가능
    };
    
    // 간단한 번역 로직
    if (sourceLanguage == 'zh' && targetLanguage == 'ko') {
      return zhToKo[text] ?? '(번역 없음)';
    } else if (sourceLanguage == 'ko' && targetLanguage == 'zh') {
      return koToZh[text] ?? '(无翻译)';
    } else {
      return '(지원되지 않는 언어 조합)';
    }
  }
  
  // 여러 텍스트 일괄 번역
  Future<List<String>> translateBatch(List<String> texts, {required String from, required String to}) async {
    final results = <String>[];
    
    for (final text in texts) {
      final translation = await translate(text, from, to);
      results.add(translation);
    }
    
    return results;
  }
  
  // 리소스 해제
  void dispose() {
    _httpClient.close();
  }
}

final translatorService = TranslatorService(); 