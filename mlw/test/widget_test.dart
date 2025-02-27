// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mlw/main.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBid3pr9pUgXowZiVo4ZRuP0C-AFuGeC38',
      appId: '1:1113863334:ios:a912bd2d8a4d2014353067',
      messagingSenderId: '1113863334',
      projectId: 'mylingowith',
      storageBucket: 'mylingowith.appspot.com',
      iosClientId: '1113863334-ios',
    ),
  );

  testWidgets('App should render properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app renders
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('MLW'), findsOneWidget);  // AppBar title
    expect(find.byIcon(Icons.add), findsOneWidget);  // FAB
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
