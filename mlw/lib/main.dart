import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/theme/app_theme.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/rendering.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: ColorTokens.semantic['surface']?['background'],
      systemNavigationBarColor: ColorTokens.semantic['surface']?['background'],
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    
    await _initializeFirebase();
    runApp(const MyApp());
  } catch (e, stack) {
    if (kDebugMode) {
      print('App initialization error: $e');
      print('Stack trace: $stack');
    }
  }
}

Future<void> _initializeFirebase() async {
  if (kDebugMode) {
    print('Starting Firebase initialization...');
  }

  try {
    if (Firebase.apps.isNotEmpty) {
      if (kDebugMode) {
        print('Firebase already initialized');
      }
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
    
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 임시 사용자 ID - 나중에 인증 시스템으로 대체
  static const String defaultUserId = 'test_user';
  static const String defaultSpaceId = 'default_space';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLW',
      theme: AppTheme.lightTheme.copyWith(
        appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
          toolbarHeight: 80, // Increased height for top padding
          titleSpacing: 4, // Side padding
        ),
        scaffoldBackgroundColor: ColorTokens.semantic['surface']?['background'],
      ),
      home: Container(
        color: ColorTokens.semantic['surface']?['background'],
        child: SafeArea(
          bottom: false,
          child: Container(
            color: ColorTokens.semantic['surface']?['background'],
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                left: 4,
                right: 4,
              ),
              child: const HomeScreen(
                userId: defaultUserId,
                spaceId: defaultSpaceId,
              ),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply global MediaQuery settings
        final mediaQuery = MediaQuery.of(context);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: 1.0,
            padding: mediaQuery.padding.copyWith(
              top: mediaQuery.padding.top + 10, // Additional top padding
            ),
          ),
          child: child!,
        );
      },
    );
  }
}