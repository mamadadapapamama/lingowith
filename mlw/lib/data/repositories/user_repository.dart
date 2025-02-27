import 'dart:convert';
import 'package:mlw/data/models/user_settings.dart';
import 'package:mlw/data/models/text_display_mode.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/datasources/local/shared_preferences_data_source.dart';
import 'package:mlw/data/models/onboarding_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/domain/models/user.dart';

class UserRepository {
  final FirebaseDataSource remoteDataSource;
  final SharedPreferencesDataSource localDataSource;
  static const String _usersCollection = 'users';
  
  static const String _settingsKey = 'user_settings';
  static const String _onboardingKey = 'onboarding_completed';
  
  UserRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  // 사용자 설정 가져오기
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      // 로컬 캐시 확인
      final cachedSettings = localDataSource.getString(_settingsKey);
      if (cachedSettings != null) {
        return UserSettings.fromJson(cachedSettings);
      }

      // 원격 데이터 가져오기
      final doc = await remoteDataSource.getDocument(_usersCollection, userId);
      if (doc.exists) {
        final settings = UserSettings.fromMap(doc.data() as Map<String, dynamic>);
        
        // 로컬 캐시 업데이트
        await localDataSource.setString(_settingsKey, jsonEncode(settings.toMap()));
        
        return settings;
      }

      // 기본 설정 생성
      final defaultSettings = _createDefaultSettings(userId);
      await remoteDataSource.setDocument(
        _usersCollection,
        userId,
        defaultSettings.toMap(),
      );
      
      // 로컬 캐시 업데이트
      await localDataSource.setString(_settingsKey, jsonEncode(defaultSettings.toMap()));
      
      return defaultSettings;
    } catch (e) {
      throw Exception('사용자 설정을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 사용자 설정 업데이트
  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      await remoteDataSource.updateDocument(
        _usersCollection,
        settings.id,
        settings.toMap(),
      );
      
      // 로컬 캐시 업데이트
      await localDataSource.setString(_settingsKey, jsonEncode(settings.toMap()));
    } catch (e) {
      throw Exception('사용자 설정을 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 온보딩 완료 상태 설정
  Future<void> setOnboardingCompleted(bool completed) async {
    await localDataSource.setBool(_onboardingKey, completed);
  }
  
  // 온보딩 완료 상태 확인
  Future<bool> isOnboardingCompleted() async {
    return localDataSource.getBool(_onboardingKey) ?? false;
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

  // OnboardingData 관련 메서드 추가
  Future<void> saveOnboardingData(OnboardingData data) async {
    try {
      // 로컬 저장소에 저장
      await localDataSource.setString('onboarding_data', jsonEncode(data.toMap()));
      
      // 원격 저장소에도 저장 (필요한 경우)
      // await remoteDataSource.updateDocument('users', userId, {'onboardingData': data.toMap()});
    } catch (e) {
      throw Exception('온보딩 데이터를 저장하는 중 오류가 발생했습니다: $e');
    }
  }

  Future<OnboardingData?> getOnboardingData() async {
    try {
      // 로컬 저장소에서 가져오기
      final dataString = localDataSource.getString('onboarding_data');
      if (dataString != null) {
        return OnboardingData.fromMap(jsonDecode(dataString));
      }
      return null;
    } catch (e) {
      throw Exception('온보딩 데이터를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  // UserRepository에 필요한 메서드 추가
  Future<void> updateUserPreference(String userId, String key, dynamic value) async {
    try {
      await remoteDataSource.updateDocument(
        'user_preferences',
        userId,
        {key: value},
      );
    } catch (e) {
      throw Exception('사용자 설정을 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }

  Future<dynamic> getUserPreference(String userId, String key) async {
    try {
      final doc = await remoteDataSource.getDocument('user_preferences', userId);
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return data[key];
    } catch (e) {
      throw Exception('사용자 설정을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final doc = await remoteDataSource.getDocument('users', userId);
      if (!doc.exists) {
        return null;
      }
      
      // Firestore 데이터를 Map으로 변환
      final data = doc.data() as Map<String, dynamic>;
      
      // Timestamp 객체를 DateTime으로 변환
      if (data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      
      if (data.containsKey('updatedAt') && data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      
      // 변환된 데이터로 User 객체 생성
      return User.fromJson(data);
    } catch (e) {
      print('사용자 설정을 가져오는중 오류가 발생했습니다: $e');
      throw Exception('사용자 설정을 가져오는중 오류가 발생했습니다: $e');
    }
  }
  
  Future<void> saveUser(User user) async {
    try {
      // User 객체를 Map으로 변환
      final userData = user.toJson();
      
      // ISO8601 문자열을 Timestamp로 변환 (필요한 경우)
      if (userData.containsKey('createdAt') && userData['createdAt'] is String) {
        userData['createdAt'] = Timestamp.fromDate(DateTime.parse(userData['createdAt']));
      }
      
      if (userData.containsKey('updatedAt') && userData['updatedAt'] is String) {
        userData['updatedAt'] = Timestamp.fromDate(DateTime.parse(userData['updatedAt']));
      }
      
      await remoteDataSource.setDocument('users', user.id, userData);
      
      // 로컬 저장소에도 저장 (필요한 경우)
      await localDataSource.saveUser(user);
    } catch (e) {
      print('사용자 설정을 저장하는중 오류가 발생했습니다: $e');
      throw Exception('사용자 설정을 저장하는중 오류가 발생했습니다: $e');
    }
  }
} 