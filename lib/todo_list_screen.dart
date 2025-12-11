import 'package:flutter/material.dart';
import 'package:todomanager/sign_in_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Todo {
  String title;
  DateTime? due;
  bool start;
  bool done;
  Todo({required this.title, this.due, this.start = false, this.done = false});
}

class TodoListScreen extends StatefulWidget {
  final String userId;  // ← ユーザーID を受け取る
  const TodoListScreen({super.key, required this.userId});
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late int _currentIndex;
  late PageController _controller;
  final List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    // PageViewで表示されているWidgetの番号を持っておく
    _currentIndex = 0;
    // PageViewの表示を切り替えるのに使う
    _controller = PageController(initialPage: _currentIndex);
    // サンプルデータ
    _loadTodos();  // ← ユーザーごとのデータを読み込む
  }

    Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'todos_${widget.userId}';  // ← ユーザーID をキーに含める
    final s = prefs.getString(key);
    if (s != null && s.isNotEmpty) {
      try {
        final List list = jsonDecode(s);
        setState(() {
          _todos.clear();
          _todos.addAll(list.map((m) => Todo(
                title: m['title'] ?? '',
                due: m['due'] != null ? DateTime.parse(m['due']) : null,
                start: m['start'] ?? false,
                done: m['done'] ?? false,
              )));
        });
      } catch (e) {
        debugPrint('データ読み込みエラー: $e'); 
      }
    } else {
      // サンプルデータ（初回のみ）
      setState(() {
        _todos.addAll([
          Todo(title: 'サンプル１', due: DateTime.now().add(const Duration(days: 1))),
          Todo(title: 'サンプル２', due: DateTime.now().add(const Duration(days: 2))),
        ]);
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'todos_${widget.userId}';  // ← ユーザーID をキーに含める
    final list = _todos.map((t) => {
          'title': t.title,
          'due': t.due?.toIso8601String(),
          'start': t.start,
          'done': t.done,
        }).toList();
    await prefs.setString(key, jsonEncode(list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TODO管理アプリ'),
        actions: [
          // ログアウト用ボタン
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SignInScreen(),
                ),
              );
            },
            icon: Icon(Icons.exit_to_app),
            tooltip: 'サインアウト',
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        // 表示が切り替わったとき
        onPageChanged: (int index) => _onPageChanged(index),
        children: [
          // TODO表を表示するページ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildTodoTable(),
          ),
          // 右ページ（別表示のプレースホルダ）
          const Center(child: Text('ページ：お気に入り')),
        ],
      ),
      // 画像追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
      // 画面下部のボタン部分
      bottomNavigationBar: BottomNavigationBar(
        // BottomNavigationBarItemがタップされたときの処理
        //   0: フォト
        //   1: お気に入り
        onTap: (int index) => _onTapBottomNavigationItem(index),
        // 現在表示されているBottomNavigationBarItemの番号
        //   0: フォト
        //   1: お気に入り
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'お気に入り',
          ),
        ],
      ),
    );
  }

  Widget _buildTodoTable() {
    // DataTable は横スクロールが必要になる可能性があるのでラップする
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('実施')),
            DataColumn(label: Text('完了')),
            DataColumn(label: Text('タイトル')),
            DataColumn(label: Text('期限')),
            DataColumn(label: Text('操作')),
          ],
          rows: List<DataRow>.generate(
            _todos.length,
            (index) {
              final todo = _todos[index];
              return DataRow(
                cells: [
                  DataCell(Checkbox(
                    value: todo.start,
                    onChanged: (v) => _toggleStart(index, v ?? false),
                  )),
                  DataCell(Checkbox(
                    value: todo.done,
                    onChanged: (v) => _toggleDone(index, v ?? false),
                  )),
                  DataCell(Text(todo.title)),
                  DataCell(Text(todo.due != null
                      ? '${todo.due!.year}/${todo.due!.month}/${todo.due!.day}'
                      : '-')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteTodo(index),
                      tooltip: '削除',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleStart(int index, bool value) {
    setState(() {
      _todos[index].start = value;
    });
    _saveTodos();
  }

  void _toggleDone(int index, bool value) {
    setState(() {
      _todos[index].done = value;
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  Future<void> _showAddTodoDialog() async {
    final titleCtrl = TextEditingController();
    DateTime? pickedDate;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('TODOを追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(pickedDate != null
                            ? '${pickedDate?.year}/${pickedDate?.month}/${pickedDate?.day}'
                            : '期限なし'),
                      ),
                      TextButton(
                        child: const Text('日付選択'),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            setStateDialog(() {
                              pickedDate = d;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      setState(() {
                        _todos.add(Todo(title: title, due: pickedDate));
                      });
                      _saveTodos();
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
    titleCtrl.dispose();
  }

  void _onPageChanged(int index) {
    // PageViewで表示されているWidgetの番号を更新
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTapBottomNavigationItem(int index) {
    // PageViewで表示するWidgetを切り替える
    _controller.animateToPage(
      // 表示するWidgetの番号
      //   0: 全ての画像
      //   1: お気に入り登録した画像
      index,
      // 表示を切り替える時にかかる時間（300ミリ秒）
      duration: const Duration(milliseconds: 300),
      // アニメーションの動き方
      //   この値を変えることで、アニメーションの動きを変えることができる
      //   https://api.flutter.dev/flutter/animation/Curves-class.html
      curve: Curves.easeIn,
    );
    // PageViewで表示されているWidgetの番号を更新
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}