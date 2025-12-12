import 'package:flutter/material.dart';
import 'package:todomanager/todo_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO管理アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // アプリ起動時にTODO画面を表示
      home: const TodoListScreen(),
    );
  }
}