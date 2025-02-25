import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/presentation/screens/home/home_screen.dart';
import 'package:mlw/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mlw/presentation/screens/settings/settings_screen.dart';
import 'package:mlw/presentation/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/presentation/screens/home/home_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    
    return _onboardingCompleted
        ? HomeScreen(userId: _userId)
        : const OnboardingScreen();
  }
}

final homeViewModel = serviceLocator.getFactory<HomeViewModel>();
