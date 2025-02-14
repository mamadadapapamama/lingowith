import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBid3pr9pUgXowZiVo4ZRuP0C-AFuGeC38',
        appId: '1:1113863334:ios:a912bd2d8a4d2014353067',
        messagingSenderId: '1113863334',
        projectId: 'mylingowith',
        storageBucket: 'mylingowith.firebasestorage.app',
        iosClientId: '1113863334-ios',
      ),
    );
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
      print('Stack trace: $stack');
    }
  }
  
  runApp(const MLWApp());
}

class MLWApp extends StatelessWidget {
  const MLWApp({super.key});

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
