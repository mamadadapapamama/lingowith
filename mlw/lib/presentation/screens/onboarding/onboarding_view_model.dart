import 'package:flutter/foundation.dart';
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/data/models/user_settings.dart';
import 'package:mlw/data/models/text_display_mode.dart';
import 'package:flutter/material.dart';
import 'package:mlw/data/models/onboarding_data.dart';
import 'package:mlw/domain/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewModel with ChangeNotifier {
  final UserService _userService;
  final OnboardingService _onboardingService;
  
  String _userId = '';
  String _preferredLanguage = '한국어';
  String _translationLanguage = '중국어';
  TextDisplayMode _displayMode = TextDisplayMode.both;
  bool _highlightEnabled = true;
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  String _error = '';
  
  OnboardingData _data = OnboardingData();
  int _currentPage = 0;
  
  OnboardingViewModel({
    required UserService userService,
    required OnboardingService onboardingService,
  }) : _userService = userService, _onboardingService = onboardingService;
  
  // Getters
  String get userId => _userId;
  String get preferredLanguage => _preferredLanguage;
  String get translationLanguage => _translationLanguage;
  TextDisplayMode get displayMode => _displayMode;
  bool get highlightEnabled => _highlightEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  OnboardingData get data => _data;
  int get currentPage => _currentPage;
  
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
  
  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }
  
  void setUserName(String name) {
    _data = _data.copyWith(userName: name);
    notifyListeners();
  }
  
  void setPreferredLanguage(String language) {
    _data = _data.copyWith(preferredLanguage: language);
    notifyListeners();
  }
  
  void setLearningLanguage(String language) {
    _data = _data.copyWith(learningLanguage: language);
    notifyListeners();
  }
  
  set data(OnboardingData value) {
    _data = value;
    notifyListeners();
  }
  
  set currentPage(int value) {
    _currentPage = value;
    notifyListeners();
  }
  
  // 온보딩 완료
  Future<bool> completeOnboarding() async {
    try {
      _setLoading(true);
      _data = _data.copyWith(completed: true);
      await _onboardingService.saveOnboardingData(_data);
      await _onboardingService.completeOnboarding();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _error = e.toString();
      return false;
    }
  }

  void setCurrentPage(int index) {}
} 