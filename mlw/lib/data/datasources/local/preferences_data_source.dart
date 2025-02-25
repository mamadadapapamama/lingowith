import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PreferencesDataSource {
  final SharedPreferences _preferences;

  PreferencesDataSource({required SharedPreferences preferences}) : _preferences = preferences;

  // 문자열 값 저장
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  // 문자열 값 가져오기
  String? getString(String key) {
    return _preferences.getString(key);
  }

  // 정수 값 저장
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }

  // 정수 값 가져오기
  int? getInt(String key) {
    return _preferences.getInt(key);
  }

  // 불리언 값 저장
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }

  // 불리언 값 가져오기
  bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  // 객체 저장 (JSON 직렬화)
  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    return await _preferences.setString(key, jsonEncode(value));
  }

  // 객체 가져오기 (JSON 역직렬화)
  Map<String, dynamic>? getObject(String key) {
    final json = _preferences.getString(key);
    if (json == null) return null;
    
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON: $e');
      return null;
    }
  }

  // 키 삭제
  Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }

  // 모든 데이터 삭제
  Future<bool> clear() async {
    return await _preferences.clear();
  }
} 