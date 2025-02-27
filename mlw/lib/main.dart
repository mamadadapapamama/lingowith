import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 추가
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/screens/onboarding_screen.dart';
import 'package:mlw/screens/settings_screen.dart';
import 'package:mlw/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:mlw/view_models/home_view_model.dart'; // 필요한 경우 주석 해제
// import 'package:mlw/firebase_options.dart'; // 필요한 경우 주석 해제

// 테스트 모드 플래그
bool useEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Flutter 바인딩 초기화 완료');
  
  // Firebase 초기화: 모바일(iOS/Android)는 plist/json 파일에서 자동 로드되고,
  // 웹에서는 DefaultFirebaseOptions.currentPlatform 옵션을 사용합니다.
  try {
    print('Firebase 초기화 시작');
    if (kIsWeb) {
      await Firebase.initializeApp();
      // 웹 설정이 필요하면 아래 주석 해제
      // await Firebase.initializeApp(options: FirebaseOptions(...));
    } else {
      await Firebase.initializeApp();
    }
    // 기본 앱 객체를 강제로 로드하여 구성이 끝났는지 확인합니다.
    final app = Firebase.app();
    print('Firebase 초기화 완료: ${app.name}');
  } catch (e) {
    if (e.toString().contains("duplicate-app")) {
      print("Firebase 이미 초기화 되어 있음");
    } else {
      print('Firebase 초기화 오류: $e');
    }
  }
  
  print('앱 실행');
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

// Firebase 에뮬레이터 설정
void setupFirebaseEmulators() async {
  await Firebase.initializeApp();
  
  // Firestore 에뮬레이터 설정
  FirebaseFirestore.instance.settings = const Settings(
    host: '127.0.0.1:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );
  
  // Auth 에뮬레이터 설정 (필요한 경우)
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  
  print('Firebase 에뮬레이터 설정 완료');
}
