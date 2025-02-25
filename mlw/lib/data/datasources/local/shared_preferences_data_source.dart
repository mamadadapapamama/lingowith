import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDataSource {
  final SharedPreferences _preferences;
  
  SharedPreferencesDataSource({
    required SharedPreferences preferences,
  }) : _preferences = preferences;
  
  // 문자열 저장
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }
  
  // 문자열 가져오기
  String? getString(String key) {
    return _preferences.getString(key);
  }
  
  // 불리언 저장
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }
  
  // 불리언 가져오기
  bool? getBool(String key) {
    return _preferences.getBool(key);
  }
  
  // 정수 저장
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }
  
  // 정수 가져오기
  int? getInt(String key) {
    return _preferences.getInt(key);
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