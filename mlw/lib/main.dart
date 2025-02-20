import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/theme/app_theme.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/services/translator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();
  
  // Initialize Services
  await TranslatorService.initialize();
  await TypographyTokens.initialize();

  runApp(const MyApp());

  // 🔥 runApp 이후에 System UI 스타일 적용 (더 확실하게 반영)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // ✅ 완전 투명하게 만들기
      statusBarIconBrightness: Brightness.dark, // ✅ 상태바 아이콘 검정색으로 (light이면 흰색)
      systemNavigationBarColor: Colors.white, // ✅ 네비게이션 바 색상 조정
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  });
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseFirestore.instance.enablePersistence();
      return;
    }

    final options = Platform.isIOS
        ? const FirebaseOptions(
            apiKey: 'AIzaSyBid3pr9pUgXowZiVo4ZRuP0C-AFuGeC38',
            appId: '1:1113863334:ios:a912bd2d8a4d2014353067',
            messagingSenderId: '1113863334',
            projectId: 'mylingowith',
            storageBucket: 'mylingowith.appspot.com',
            iosClientId: '1113863334-ios',
          )
        : const FirebaseOptions(
            apiKey: 'AIzaSyBid3pr9pUgXowZiVo4ZRuP0C-AFuGeC38',
            appId: '1:1113863334:android:YOUR_ANDROID_APP_ID',
            messagingSenderId: '1113863334',
            projectId: 'mylingowith',
            storageBucket: 'mylingowith.appspot.com',
          );

    await Firebase.initializeApp(options: options);
    await FirebaseFirestore.instance.enablePersistence();
    
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String defaultUserId = 'test_user';
  static const String defaultSpaceId = 'default_space';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLW',
      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: ColorTokens.semantic['surface']?['background'],
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreenWrapper(),
    );
  }
}

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ 상태바 뒤까지 확장
      body: Container(
        color: ColorTokens.semantic['surface']?['background'] ?? Colors.white, // ✅ 배경색 확실히 적용
        child: HomeScreen(
          userId: MyApp.defaultUserId,
          spaceId: MyApp.defaultSpaceId,
        ),
      ),
    );
  }
}
