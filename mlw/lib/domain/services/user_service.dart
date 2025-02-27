import 'package:mlw/data/repositories/user_repository.dart';
import 'package:mlw/data/models/user_settings.dart';
import 'package:mlw/data/models/text_display_mode.dart';
import 'package:mlw/domain/models/user.dart';

class UserService {
  final UserRepository _repository;

  UserService({required UserRepository repository}) : _repository = repository;

  // 사용자 설정 가져오기
  Future<UserSettings> getUserSettings(String userId) async {
    return await _repository.getUserSettings(userId);
  }

  // 사용자 설정 업데이트
  Future<void> updateUserSettings(UserSettings settings) async {
    await _repository.updateUserSettings(settings);
  }

  // 사용자 언어 설정 업데이트
  Future<void> updateLanguageSettings(
    String userId, 
    String preferredLanguage, 
    String translationLanguage
  ) async {
    final settings = await _repository.getUserSettings(userId);
    
    final updatedSettings = settings.copyWith(
      preferredLanguage: preferredLanguage,
      translationLanguage: translationLanguage,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateUserSettings(updatedSettings);
  }

  // 사용자 표시 모드 업데이트
  Future<void> updateDisplayMode(
    String userId, 
    TextDisplayMode displayMode
  ) async {
    final settings = await _repository.getUserSettings(userId);
    
    final updatedSettings = settings.copyWith(
      displayMode: displayMode,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateUserSettings(updatedSettings);
  }

  // 하이라이트 설정 업데이트
  Future<void> updateHighlightSettings(
    String userId, 
    bool enabled
  ) async {
    final settings = await _repository.getUserSettings(userId);
    
    final updatedSettings = settings.copyWith(
      highlightEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateUserSettings(updatedSettings);
  }

  // 알림 설정 업데이트
  Future<void> updateNotificationSettings(
    String userId, 
    bool enabled
  ) async {
    final settings = await _repository.getUserSettings(userId);
    
    final updatedSettings = settings.copyWith(
      notificationsEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateUserSettings(updatedSettings);
  }

  // 다크 모드 설정 업데이트
  Future<void> updateDarkModeSettings(
    String userId, 
    bool enabled
  ) async {
    final settings = await _repository.getUserSettings(userId);
    
    final updatedSettings = settings.copyWith(
      darkModeEnabled: enabled,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateUserSettings(updatedSettings);
  }

  // 온보딩 완료 상태 설정
  Future<void> setOnboardingCompleted(bool completed) async {
    await _repository.setOnboardingCompleted(completed);
  }

  // 온보딩 완료 상태 확인
  Future<bool> isOnboardingCompleted() async {
    return await _repository.isOnboardingCompleted();
  }

  Future<User?> getUser(String userId) async {
    return await _repository.getUser(userId);
  }
} 