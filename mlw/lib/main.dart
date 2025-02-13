import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization error: $e');
    // 이미 초기화된 경우 무시
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized');
    } else {
      rethrow;
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
    );
  }
}
