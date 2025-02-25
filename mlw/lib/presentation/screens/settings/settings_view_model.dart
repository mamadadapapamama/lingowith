import 'package:flutter/foundation.dart';
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/domain/services/notification_service.dart';
import 'package:mlw/data/models/user_settings.dart';
import 'package:mlw/data/models/text_display_mode.dart';

class SettingsViewModel with ChangeNotifier {
  final UserService _userService;
  final NotificationService _notificationService;
  
  UserSettings? _userSettings;
  bool _isLoading = false;
  String _error = '';
  
  SettingsViewModel({
    required UserService userService,
    required NotificationService notificationService,
  }) : 
    _userService = userService,
    _notificationService = notificationService;
  
  // Getters
  UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // 사용자 설정 로드
  Future<void> loadUserSettings(String userId) async {
    _setLoading(true);
    try {
      _userSettings = await _userService.getUserSettings(userId);
      _error = '';
    } catch (e) {
      _error = '설정을 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 언어 설정 업데이트
  Future<void> updateLanguageSettings(
    String userId,
    String preferredLanguage,
    String translationLanguage,
  ) async {
    _setLoading(true);
    try {
      await _userService.updateLanguageSettings(
        userId,
        preferredLanguage,
        translationLanguage,
      );
      _userSettings = await _userService.getUserSettings(userId);
      _error = '';
    } catch (e) {
      _error = '언어 설정을 업데이트하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 표시 모드 업데이트
  Future<void> updateDisplayMode(
    String userId,
    TextDisplayMode displayMode,
  ) async {
    _setLoading(true);
    try {
      await _userService.updateDisplayMode(userId, displayMode);
      _userSettings = await _userService.getUserSettings(userId);
      _error = '';
    } catch (e) {
      _error = '표시 모드를 업데이트하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 알림 설정 업데이트
  Future<void> updateNotificationSettings(
    String userId,
    bool enabled,
  ) async {
    _setLoading(true);
    try {
      await _userService.updateNotificationSettings(userId, enabled);
      
      if (enabled) {
        await _notificationService.scheduleNotifications();
      } else {
        await _notificationService.cancelAllNotifications();
      }
      
      _userSettings = await _userService.getUserSettings(userId);
      _error = '';
    } catch (e) {
      _error = '알림 설정을 업데이트하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 다크 모드 설정 업데이트
  Future<void> updateDarkModeSettings(
    String userId,
    bool enabled,
  ) async {
    _setLoading(true);
    try {
      await _userService.updateDarkModeSettings(userId, enabled);
      _userSettings = await _userService.getUserSettings(userId);
      _error = '';
    } catch (e) {
      _error = '다크 모드 설정을 업데이트하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 하이라이트 설정 업데이트
  Future<void> updateHighlightSettings(
    String userId,
    bool enabled,
  ) async {
    _setLoading(true);
    try {
      await _userService.updateHighlightSettings(userId, enabled);
      _userSettings = await _userService.getUserSettings(userId);
      _error = '';
    } catch (e) {
      _error = '하이라이트 설정을 업데이트하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 