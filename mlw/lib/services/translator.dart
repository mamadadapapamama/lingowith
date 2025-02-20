import 'package:googleapis/translate/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationCache {
  static final Map<String, _CacheEntry> _memoryCache = {};
  static const String _prefsKey = 'translation_cache';
  static const int _maxEntries = 5000;  // 최대 캐시 항목 수
  static const Duration _maxAge = Duration(days: 30);  // 캐시 유효 기간
  static SharedPreferences? _prefs;
  
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
  }
  
  static String? get(String text, String from, String to) {
    final key = _generateKey(text, from, to);
    final entry = _memoryCache[key];
    if (entry == null) return null;
    
    // 오래된 캐시 항목 제거
    if (DateTime.now().difference(entry.timestamp) > _maxAge) {
      _memoryCache.remove(key);
      _saveToDisk();
      return null;
    }
    
    // 접근 시간 업데이트
    entry.lastAccessed = DateTime.now();
    return entry.translation;
  }
  
  static Future<void> set(String text, String from, String to, String translation) async {
    final key = _generateKey(text, from, to);
    
    // 캐시가 최대 크기에 도달하면 가장 오래된 항목 제거
    if (_memoryCache.length >= _maxEntries) {
      _removeOldestEntry();
    }
    
    _memoryCache[key] = _CacheEntry(
      translation: translation,
      timestamp: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
    
    await _saveToDisk();
  }
  
  static Future<void> clear() async {
    _memoryCache.clear();
    await _prefs?.remove(_prefsKey);
  }
  
  static String _generateKey(String text, String from, String to) {
    return '${text}_${from}_$to';
  }
  
  static void _removeOldestEntry() {
    if (_memoryCache.isEmpty) return;
    
    var oldestKey = _memoryCache.entries.first.key;
    var oldestAccess = _memoryCache.entries.first.value.lastAccessed;
    
    for (var entry in _memoryCache.entries) {
      if (entry.value.lastAccessed.isBefore(oldestAccess)) {
        oldestKey = entry.key;
        oldestAccess = entry.value.lastAccessed;
      }
    }
    
    _memoryCache.remove(oldestKey);
  }
  
  static Future<void> _loadFromDisk() async {
    final jsonString = _prefs?.getString(_prefsKey);
    if (jsonString == null) return;
    
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final now = DateTime.now();
    
    _memoryCache.clear();
    json.forEach((key, value) {
      final entry = _CacheEntry.fromJson(value);
      // 유효한 캐시만 로드
      if (now.difference(entry.timestamp) <= _maxAge) {
        _memoryCache[key] = entry;
      }
    });
  }
  
  static Future<void> _saveToDisk() async {
    final Map<String, dynamic> json = {};
    _memoryCache.forEach((key, value) {
      json[key] = value.toJson();
    });
    
    await _prefs?.setString(_prefsKey, jsonEncode(json));
  }
}

class _CacheEntry {
  final String translation;
  final DateTime timestamp;
  DateTime lastAccessed;
  
  _CacheEntry({
    required this.translation,
    required this.timestamp,
    required this.lastAccessed,
  });
  
  Map<String, dynamic> toJson() => {
    'translation': translation,
    'timestamp': timestamp.toIso8601String(),
    'lastAccessed': lastAccessed.toIso8601String(),
  };
  
  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
    translation: json['translation'],
    timestamp: DateTime.parse(json['timestamp']),
    lastAccessed: DateTime.parse(json['lastAccessed']),
  );
}

class TranslatorService {
  static Future<void> initialize() async {
    await TranslationCache.initialize();
  }
  
  Future<String> translate(String text, {String from = 'zh', String to = 'ko'}) async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final jsonMap = json.decode(keyJson);
      final projectId = jsonMap['project_id'] as String;
      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-translation'],
      );
      final api = TranslateApi(client);

      try {
        final parent = 'projects/$projectId/locations/global';
        final request = TranslateTextRequest(
          contents: [text],
          sourceLanguageCode: from,
          targetLanguageCode: to,
        );

        final response = await api.projects.locations.translateText(request, parent);

        if (response.translations == null || response.translations!.isEmpty) {
          throw Exception('No translation result');
        }

        return response.translations!.first.translatedText ?? text;
      } finally {
        client.close();
      }
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  Future<List<String>> translateBatch(List<String> texts, {String from = 'zh', String to = 'ko'}) async {
    if (texts.isEmpty) return [];

    try {
      // Check cache for all texts
      final List<String?> cachedTranslations = texts.map((text) => 
        TranslationCache.get(text, from, to)
      ).toList();

      // If all translations are cached, return them
      if (!cachedTranslations.contains(null)) {
        print('Using cached translations for batch');
        return cachedTranslations.cast<String>();
      }

      // Get texts that need translation
      final List<String> textsToTranslate = [];
      final List<int> indices = [];
      for (int i = 0; i < texts.length; i++) {
        if (cachedTranslations[i] == null) {
          textsToTranslate.add(texts[i]);
          indices.add(i);
        }
      }

      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final jsonMap = json.decode(keyJson);
      final projectId = jsonMap['project_id'] as String;

      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(
        credentials, 
        ['https://www.googleapis.com/auth/cloud-translation'],
      );

      final api = TranslateApi(client);
      final parent = 'projects/$projectId/locations/global';
      
      final request = TranslateTextRequest(
        contents: textsToTranslate,
        sourceLanguageCode: from,
        targetLanguageCode: to,
      );
      
      final response = await api.projects.locations.translateText(request, parent);
      final translations = response.translations?.map((t) => t.translatedText ?? '').toList() ?? [];

      // Cache new translations
      for (int i = 0; i < translations.length; i++) {
        TranslationCache.set(textsToTranslate[i], from, to, translations[i]);
      }

      // Merge cached and new translations
      final List<String> result = List.from(cachedTranslations);
      for (int i = 0; i < translations.length; i++) {
        result[indices[i]] = translations[i];
      }

      return result.cast<String>();
    } catch (e, stackTrace) {
      print('Batch translation error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

final translatorService = TranslatorService(); 