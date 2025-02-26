import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDataSource {
  final SharedPreferences sharedPreferences;
  
  SharedPreferencesDataSource({
    required this.sharedPreferences,
  });
  
  // 문자열 저장
  Future<bool> setString(String key, String value) async {
    return await sharedPreferences.setString(key, value);
  }
  
  // 문자열 가져오기
  String? getString(String key) {
    return sharedPreferences.getString(key);
  }
  
  // 불리언 저장
  Future<bool> setBool(String key, bool value) async {
    return await sharedPreferences.setBool(key, value);
  }
  
  // 불리언 가져오기
  bool? getBool(String key) {
    return sharedPreferences.getBool(key);
  }
  
  // 정수 저장
  Future<bool> setInt(String key, int value) async {
    return await sharedPreferences.setInt(key, value);
  }
  
  // 정수 가져오기
  int? getInt(String key) {
    return sharedPreferences.getInt(key);
  }
  
  // 키 삭제
  Future<bool> remove(String key) async {
    return await sharedPreferences.remove(key);
  }
  
  // 모든 데이터 삭제
  Future<bool> clear() async {
    return await sharedPreferences.clear();
  }
} 