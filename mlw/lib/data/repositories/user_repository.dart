import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mlw/data/models/user_settings.dart';
import 'package:mlw/data/models/text_display_mode.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/datasources/local/shared_preferences_data_source.dart';

class UserRepository {
  final FirebaseDataSource _remoteDataSource;
  final SharedPreferencesDataSource _localDataSource;
  static const String _usersCollection = 'users';
  
  static const String _settingsKey = 'user_settings';
  static const String _onboardingKey = 'onboarding_completed';
  
  UserRepository({
    required FirebaseDataSource remoteDataSource,
    required SharedPreferencesDataSource localDataSource,
  }) : 
    _remoteDataSource = remoteDataSource,
    _localDataSource = localDataSource;
  
  // 사용자 설정 가져오기
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      // 로컬 캐시 확인
      final cachedSettings = _localDataSource.getString(_settingsKey);
      if (cachedSettings != null) {
        return UserSettings.fromJson(cachedSettings);
      }

      // 원격 데이터 가져오기
      final doc = await _remoteDataSource.getDocument(_usersCollection, userId);
      if (doc.exists) {
        final settings = UserSettings.fromMap(doc.data() as Map<String, dynamic>);
        
        // 로컬 캐시 업데이트
        await _localDataSource.setString(_settingsKey, jsonEncode(settings.toMap()));
        
        return settings;
      }

      // 기본 설정 생성
      final defaultSettings = _createDefaultSettings(userId);
      await _remoteDataSource.setDocument(
        _usersCollection,
        userId,
        defaultSettings.toMap(),
      );
      
      // 로컬 캐시 업데이트
      await _localDataSource.setString(_settingsKey, jsonEncode(defaultSettings.toMap()));
      
      return defaultSettings;
    } catch (e) {
      throw Exception('사용자 설정을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 사용자 설정 업데이트
  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      await _remoteDataSource.updateDocument(
        _usersCollection,
        settings.id,
        settings.toMap(),
      );
      
      // 로컬 캐시 업데이트
      await _localDataSource.setString(_settingsKey, jsonEncode(settings.toMap()));
    } catch (e) {
      throw Exception('사용자 설정을 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 온보딩 완료 상태 설정
  Future<void> setOnboardingCompleted(bool completed) async {
    await _localDataSource.setBool(_onboardingKey, completed);
  }
  
  // 온보딩 완료 상태 확인
  Future<bool> isOnboardingCompleted() async {
    return _localDataSource.getBool(_onboardingKey) ?? false;
  }
  
  // 기본 사용자 설정 생성
  UserSettings _createDefaultSettings(String userId) {
    return UserSettings(
      id: userId,
      preferredLanguage: '한국어',
      translationLanguage: '중국어',
      displayMode: TextDisplayMode.both,
      highlightEnabled: true,
      notificationsEnabled: true,
      darkModeEnabled: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 