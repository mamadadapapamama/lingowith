import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 추가
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mlw/screens/home/home_screen.dart';
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
  await Firebase.initializeApp();
  
  // 에뮬레이터 비활성화
  // if (kDebugMode) {
  //   setupFirebaseEmulators();
  // }
  
  // 초기 데이터 생성
  await createInitialData();
  
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
        '/home': (context) => const HomeScreen(),  // 이제 새 구조의 HomeScreen을 가리킴
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
void setupFirebaseEmulators() {
  FirebaseFirestore.instance.settings = const Settings(
    host: '127.0.0.1:8080',
    sslEnabled: false,
    persistenceEnabled: false,
  );
  
  print('Firebase 에뮬레이터 설정 완료');
}

Future<void> createInitialData() async {
  try {
    print('초기 데이터 생성 시작');
    // 기본 사용자 ID
    const userId = 'test_user_id';
    
    // 노트 스페이스 컬렉션 확인
    final spaceSnapshot = await FirebaseFirestore.instance
        .collection('note_spaces')
        .where('userId', isEqualTo: userId)
        .get();
    
    print('노트 스페이스 쿼리 결과: ${spaceSnapshot.docs.length}개');
    
    // 노트 스페이스가 없으면 생성
    if (spaceSnapshot.docs.isEmpty) {
      print('기본 노트 스페이스 생성');
      final spaceRef = await FirebaseFirestore.instance.collection('note_spaces').add({
        'userId': userId,
        'name': '기본 스페이스',
        'language': 'ko',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isFlashcardEnabled': true,
        'isTTSEnabled': true,
        'isPinyinEnabled': true,
      });
      
      print('기본 노트 스페이스 생성 완료: ${spaceRef.id}');
      
      // 기본 노트 생성
      await FirebaseFirestore.instance.collection('notes').add({
        'spaceId': spaceRef.id,
        'userId': userId,
        'title': '샘플 노트',
        'content': '이것은 샘플 노트입니다.',
        'imageUrl': '',
        'extractedText': '샘플 텍스트',
        'translatedText': '샘플 번역',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isDeleted': false,
      });
      
      print('기본 노트 생성 완료');
    } else {
      print('기존 노트 스페이스 발견: ${spaceSnapshot.docs.length}개');
      
      // 기존 노트 확인
      final spaceId = spaceSnapshot.docs.first.id;
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print('기존 노트 발견: ${notesSnapshot.docs.length}개');
      
      // 노트가 없으면 샘플 노트 생성
      if (notesSnapshot.docs.isEmpty) {
        print('샘플 노트 생성');
        await FirebaseFirestore.instance.collection('notes').add({
          'spaceId': spaceId,
          'userId': userId,
          'title': '샘플 노트',
          'content': '이것은 샘플 노트입니다.',
          'imageUrl': '',
          'extractedText': '샘플 텍스트',
          'translatedText': '샘플 번역',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'isDeleted': false,
        });
        
        print('샘플 노트 생성 완료');
      }
    }
    
    print('초기 데이터 생성 완료');
  } catch (e) {
    print('초기 데이터 생성 오류: $e');
    print('스택 트레이스: ${StackTrace.current}');
  }
}
