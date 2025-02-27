import 'package:flutter/material.dart';
import 'package:mlw/presentation/screens/home/home_screen.dart';
import 'package:mlw/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mlw/presentation/screens/settings/settings_screen.dart';
import 'package:mlw/presentation/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final String _userId = 'test_user_id'; // 실제 앱에서는 인증 서비스에서 가져옴
  bool _initialized = false;
  bool _onboardingCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }
  
  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('onboarding_completed') ?? false;
      
      // 디버깅을 위한 로그 추가
      print('Onboarding completed: $completed');
      
      if (mounted) {
        setState(() {
          _onboardingCompleted = completed;
          _initialized = true;
        });
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _initialized = true; // 오류가 발생해도 앱은 계속 진행
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLW - 중국어 학습 도우미',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _buildHomeScreen(),
      routes: {
        '/settings': (context) => SettingsScreen(userId: _userId),
      },
    );
  }
  
  Widget _buildHomeScreen() {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // 디버깅을 위한 로그 추가
    print('Building home screen. Onboarding completed: $_onboardingCompleted');
    
    // 임시 해결책: 항상 홈 화면으로 이동
    return HomeScreen(userId: _userId);
    
    // 원래 코드:
    // return _onboardingCompleted
    //     ? HomeScreen(userId: _userId)
    //     : const OnboardingScreen();
  }
} 