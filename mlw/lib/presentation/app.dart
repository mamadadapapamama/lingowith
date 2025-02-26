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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLW - 중국어 학습 도우미',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: _initialized 
          ? (_onboardingCompleted ? '/home' : '/onboarding')
          : '/loading',
      routes: {
        '/loading': (context) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => HomeScreen(userId: _userId),
        '/settings': (context) => SettingsScreen(userId: _userId),
      },
    );
  }
} 