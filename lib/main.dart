import 'package:flutter/material.dart';
import 'package:todomanager/sign_in_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // アプリ起動時にログイン画面を表示
      home: SignInScreen(),
    );
  }
}