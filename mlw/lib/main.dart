import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/presentation/screens/home/home_screen.dart';
import 'package:mlw/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:mlw/presentation/screens/settings/settings_screen.dart';
import 'package:mlw/presentation/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/presentation/screens/home/home_view_model.dart';
import 'package:mlw/firebase_options.dart';
import 'package:mlw/utils/firebase_config_loader.dart';
import 'package:mlw/presentation/app.dart';

// 테스트 모드 플래그
bool useEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp();
  
  // 서비스 로케이터 설정
  await setupServiceLocator();
  
  runApp(const App());
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

final homeViewModel = serviceLocator.get<HomeViewModel>();

// Firebase 에뮬레이터 설정
void setupFirebaseEmulators() async {
  await Firebase.initializeApp();
  
  // Firestore 에뮬레이터 설정
  FirebaseFirestore.instance.settings = Settings(
    host: '127.0.0.1:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );
  
  // Auth 에뮬레이터 설정 (필요한 경우)
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  
  print('Firebase 에뮬레이터 설정 완료');
}
