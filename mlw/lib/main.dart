import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
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
      
      if (kDebugMode) {
        print('Firebase initialized with options');
      }
    } else {
      if (kDebugMode) {
        print('Firebase already initialized');
      }
    }

    // Firestore 설정
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (kDebugMode) {
      print('Firestore settings configured');
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
      print('Stack trace: $stack');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MLW',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}