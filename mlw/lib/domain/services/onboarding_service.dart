import 'package:mlw/data/models/onboarding_data.dart';
import 'package:mlw/data/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  final UserRepository repository;
  
  OnboardingService({required this.repository});
  
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
  
  Future<void> saveOnboardingData(OnboardingData data) async {
    await repository.saveOnboardingData(data);
  }
  
  Future<void> completeOnboarding() async {
    // 온보딩 완료 시 필요한 초기 설정 작업 수행
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // 여기에 추가적인 온보딩 완료 로직 구현 가능
    // 예: 초기 데이터 생성, 알림 설정 등
  }
  
  Future<OnboardingData?> getOnboardingData() async {
    return await repository.getOnboardingData();
  }
  
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
  }
} 