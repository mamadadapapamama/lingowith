import 'package:flutter/foundation.dart';
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/data/models/user_settings.dart';
import 'package:mlw/data/models/text_display_mode.dart';

class OnboardingViewModel with ChangeNotifier {
  final UserService _userService;
  
  String _userId = '';
  String _preferredLanguage = '한국어';
  String _translationLanguage = '중국어';
  TextDisplayMode _displayMode = TextDisplayMode.both;
  bool _highlightEnabled = true;
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  String _error = '';
  
  OnboardingViewModel({
    required UserService userService,
  }) : _userService = userService;
  
  // Getters
  String get userId => _userId;
  String get preferredLanguage => _preferredLanguage;
  String get translationLanguage => _translationLanguage;
  TextDisplayMode get displayMode => _displayMode;
  bool get highlightEnabled => _highlightEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Setters
  set userId(String value) {
    _userId = value;
    notifyListeners();
  }
  
  set preferredLanguage(String value) {
    _preferredLanguage = value;
    notifyListeners();
  }
  
  set translationLanguage(String value) {
    _translationLanguage = value;
    notifyListeners();
  }
  
  set displayMode(TextDisplayMode value) {
    _displayMode = value;
    notifyListeners();
  }
  
  set highlightEnabled(bool value) {
    _highlightEnabled = value;
    notifyListeners();
  }
  
  set notificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  // 온보딩 완료
  Future<bool> completeOnboarding() async {
    _setLoading(true);
    
    try {
      final now = DateTime.now();
      
      final settings = UserSettings(
        id: _userId,
        preferredLanguage: _preferredLanguage,
        translationLanguage: _translationLanguage,
        displayMode: _displayMode,
        highlightEnabled: _highlightEnabled,
        notificationsEnabled: _notificationsEnabled,
        darkModeEnabled: false,
        createdAt: now,
        updatedAt: now,
      );
      
      await _userService.updateUserSettings(settings);
      await _userService.setOnboardingCompleted(true);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('온보딩을 완료하는 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return false;
    }
  }
} 