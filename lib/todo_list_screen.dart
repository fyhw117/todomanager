import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Todo {
  String title;
  DateTime? due;
  bool start;
  bool done;
  DateTime? completedDate;
  DateTime? startDate;
  String memo;
  Todo({required this.title, this.due, this.start = false, this.done = false, this.completedDate, this.startDate, this.memo = ''});
}

class Routine {
  String title;
  DateTime? executionDate;
  List<int> weekdays;
  String frequency;
  String timeSlot;
  DateTime startDate;
  String memo;
  int? weekOfMonth; // 第何週か (1-5, null=未指定)
  Routine({
    required this.title,
    this.executionDate,
    required this.weekdays,
    required this.frequency,
    required this.timeSlot,
    required this.startDate,
    this.memo = '',
    this.weekOfMonth,
  });
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});
  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late int _currentIndex;
  late PageController _controller;
  final List<Todo> _todos = [];
  final List<Routine> _routines = [];
  final Map<String, String> _routineDoneMap = {}; // title -> ISO date of last done
  static const _prefsKey = 'todos_local_user';
  static const _routinesPrefsKey = 'routines_local_user';
  static const _routineDonePrefsKey = 'routine_done_local_user';

  @override
  void initState() {
    super.initState();
    // PageViewで表示されているWidgetの番号を持っておく
    _currentIndex = 0;
    // PageViewの表示を切り替えるのに使う
    _controller = PageController(initialPage: _currentIndex);
    // サンプルデータ
    _loadTodos();
    _loadRoutines();
    _loadRoutineDone();
  }

    Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);
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
                completedDate: m['completedDate'] != null ? DateTime.parse(m['completedDate']) : null,
                startDate: m['startDate'] != null ? DateTime.parse(m['startDate']) : null,
                memo: m['memo'] ?? '',
              )));
        });
        // 前日以前の実施チェックをリセット
        _resetOldStartChecks();
      } catch (e) {
        debugPrint('データ読み込みエラー: $e'); 
      }
    } else {
      // サンプルデータ（初回のみ）
      setState(() {
        _todos.addAll([
          Todo(title: 'サンプル１', due: DateTime.now().add(const Duration(days: 1))),
          Todo(title: 'サンプル２', due: DateTime.now().add(const Duration(days: 2))),
          // 完了済サンプルタスク
          Todo(
            title: '完了済サンプル１',
            due: DateTime.now().subtract(const Duration(days: 3)),
            done: true,
            completedDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Todo(
            title: '完了済サンプル２',
            due: DateTime.now().subtract(const Duration(days: 5)),
            done: true,
            completedDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _todos.map((t) => {
          'title': t.title,
          'due': t.due?.toIso8601String(),
          'start': t.start,
          'done': t.done,
          'completedDate': t.completedDate?.toIso8601String(),
          'startDate': t.startDate?.toIso8601String(),
          'memo': t.memo,
        }).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(148, 91, 196, 49),
        title: Text('TODO Manager'),
      ),
      body: PageView(
        controller: _controller,
        // 表示が切り替わったとき
        onPageChanged: (int index) => _onPageChanged(index),
        children: [
          // todo表を表示するページ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildTodoTable(),
          ),
          // 今日のルーティン実施ページ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildTodayRoutineList(),
          ),
          // ルーティン一覧ページ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildRoutineTable(),
          ),
          // 完了済タスク一覧ページ
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildCompletedTodoTable(),
          ),
        ],
      ),
      // 追加ボタン
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 45, 100, 23),
        onPressed: _currentIndex == 2 ? _showAddRoutineDialog : _showAddTodoDialog,
        child: const Icon(
          Icons.add,
          color: Colors.white,),
      ),
      // 画面下部のボタン部分
      bottomNavigationBar: BottomNavigationBar(
        // BottomNavigationBarItemがタップされたときの処理
        //   0: 一覧
        //   1: 完了済
        //   2: ルーティン
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(148, 91, 196, 49),
        onTap: (int index) => _onTapBottomNavigationItem(index),
        // 現在表示されているBottomNavigationBarItemの番号
        //   0: 一覧
        //   1: 完了済
        //   2: ルーティン
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'TODO一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: '今日のルーティン',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: 'ルーティン編集',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: '完了済タスク',
          ),
        ],
      ),
    );
  }

  Widget _buildTodoTable() {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    // 前日以前に完了したタスクを除外
    final activeTodos = _todos.where((todo) {
      if (!todo.done) return true;  // 未完了は表示
      if (todo.completedDate == null) return true;  // 完了日なしは表示
      return !todo.completedDate!.isBefore(todayMidnight);  // 今日以降に完了したものは表示
    }).toList();
    
    // DataTable は横スクロールが必要になる可能性があるのでラップする
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            columnSpacing: 24,
            horizontalMargin: 16,
            dividerThickness: 1,
            border: TableBorder(
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
              horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          columns: const [
            DataColumn(label: Text('実施', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('完了', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('タイトル', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('期限', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('操作', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: List<DataRow>.generate(
            activeTodos.length,
            (index) {
              final todo = activeTodos[index];
              final originalIndex = _todos.indexOf(todo);
              return DataRow(
                cells: [
                  DataCell(Checkbox(
                    value: todo.start,
                    onChanged: (v) => _toggleStart(originalIndex, v ?? false),
                  )),
                  DataCell(Checkbox(
                    value: todo.done,
                    onChanged: (v) => _toggleDone(originalIndex, v ?? false),
                  )),
                  DataCell(Text(todo.title)),
                  DataCell(Text(todo.due != null
                      ? '${todo.due!.year}/${todo.due!.month}/${todo.due!.day}'
                      : '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            todo.memo.isEmpty ? Icons.note_add : Icons.note,
                            color: todo.memo.isEmpty ? null : Colors.blue,
                          ),
                          onPressed: () => _showMemoDialog(originalIndex),
                          tooltip: 'メモ',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTodo(originalIndex),
                          tooltip: '削除',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTodoTable() {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    
    final completedTodos = _todos.where((todo) {
      if (!todo.done) return false;
      if (todo.completedDate == null) return false;
      return todo.completedDate!.isBefore(todayMidnight);
    }).toList();
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            columnSpacing: 24,
            horizontalMargin: 16,
            dividerThickness: 1,
            border: TableBorder(
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
              horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          columns: const [
            DataColumn(label: Text('タイトル', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('期限', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('完了日', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('操作', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: List<DataRow>.generate(
            completedTodos.length,
            (index) {
              final todo = completedTodos[index];
              final originalIndex = _todos.indexOf(todo);
              return DataRow(
                cells: [
                  DataCell(Text(todo.title)),
                  DataCell(Text(todo.due != null
                      ? '${todo.due!.year}/${todo.due!.month}/${todo.due!.day}'
                      : '-')),
                  DataCell(Text(todo.completedDate != null
                      ? '${todo.completedDate!.year}/${todo.completedDate!.month}/${todo.completedDate!.day}'
                      : '-')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            todo.memo.isEmpty ? Icons.note_add : Icons.note,
                            color: todo.memo.isEmpty ? null : Colors.blue,
                          ),
                          onPressed: () => _showMemoDialog(originalIndex),
                          tooltip: 'メモ',
                        ),
                        IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: () => _toggleDone(originalIndex, false),
                          tooltip: '未完了に戻す',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_routinesPrefsKey);
    if (s != null && s.isNotEmpty) {
      try {
        final List list = jsonDecode(s);
        setState(() {
          _routines.clear();
          _routines.addAll(list.map((m) => Routine(
                title: m['title'] ?? '',
                executionDate: m['executionDate'] != null ? DateTime.parse(m['executionDate']) : null,
                weekdays: List<int>.from(m['weekdays'] ?? []),
                frequency: m['frequency'] ?? '毎日',
                timeSlot: m['timeSlot'] ?? '指定なし',
                startDate: DateTime.parse(m['startDate'] ?? DateTime.now().toIso8601String()),
                memo: m['memo'] ?? '',
                weekOfMonth: m['weekOfMonth'],
              )));
        });
      } catch (e) {
        debugPrint('ルーティン読み込みエラー: $e');
      }
    }
  }

  Future<void> _saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _routines.map((r) => {
          'title': r.title,
          'executionDate': r.executionDate?.toIso8601String(),
          'weekdays': r.weekdays,
          'frequency': r.frequency,
          'timeSlot': r.timeSlot,
          'startDate': r.startDate.toIso8601String(),
          'memo': r.memo,
          'weekOfMonth': r.weekOfMonth,
        }).toList();
    await prefs.setString(_routinesPrefsKey, jsonEncode(list));
  }

  Future<void> _loadRoutineDone() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_routineDonePrefsKey);
    if (s == null || s.isEmpty) return;
    try {
      final Map<String, dynamic> map = jsonDecode(s);
      setState(() {
        _routineDoneMap.clear();
        _routineDoneMap.addAll(map.map((k, v) => MapEntry(k, v.toString())));
      });
    } catch (e) {
      debugPrint('ルーティン実施状況読み込みエラー: $e');
    }
  }

  Future<void> _saveRoutineDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routineDonePrefsKey, jsonEncode(_routineDoneMap));
  }

  Widget _buildRoutineTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.purple.shade50),
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            columnSpacing: 24,
            horizontalMargin: 16,
            dividerThickness: 1,
            border: TableBorder(
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
              horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          columns: const [
            DataColumn(label: Text('タイトル', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('頻度', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('時間帯', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('曜日', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('開始日', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('操作', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: List<DataRow>.generate(
            _routines.length,
            (index) {
              final routine = _routines[index];
              final weekdayNames = ['日', '月', '火', '水', '木', '金', '土'];
              final weekdayStr = routine.weekdays.isEmpty
                  ? '-'
                  : routine.weekdays.map((w) => weekdayNames[w]).join(',');
              return DataRow(
                cells: [
                  DataCell(Text(routine.title)),
                  DataCell(Text(routine.frequency)),
                  DataCell(Text(routine.timeSlot)),
                  DataCell(Text(weekdayStr)),
                  DataCell(Text('${routine.startDate.year}/${routine.startDate.month}/${routine.startDate.day}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            routine.memo.isEmpty ? Icons.note_add : Icons.note,
                            color: routine.memo.isEmpty ? null : Colors.blue,
                          ),
                          onPressed: () => _showRoutineMemoDialog(index),
                          tooltip: 'メモ',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditRoutineDialog(index),
                          tooltip: '編集',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRoutine(index),
                          tooltip: '削除',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayRoutineList() {
    final today = _dateOnly(DateTime.now());
    final routinesToday = _routines.where((r) => _routineShouldRunToday(r, today)).toList();

    if (routinesToday.isEmpty) {
      return const Center(child: Text('今日実施のルーティンはありません'));
    }

    return ListView.separated(
      itemCount: routinesToday.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = routinesToday[index];
        final done = _isRoutineDoneToday(r.title, today);
        return ListTile(
          leading: Checkbox(
            value: done,
            onChanged: (v) => _toggleRoutineDone(r.title, v ?? false, today),
          ),
          title: Text(r.title),
          subtitle: Text(r.timeSlot == '指定なし' ? '時間帯: 未設定' : '時間帯: ${r.timeSlot}'),
          trailing: IconButton(
            icon: Icon(
              r.memo.isEmpty ? Icons.note_add : Icons.note,
              color: r.memo.isEmpty ? null : Colors.blue,
            ),
            onPressed: () => _showRoutineMemoDialog(_routines.indexOf(r)),
            tooltip: 'メモ',
          ),
        );
      },
    );
  }

  void _deleteRoutine(int index) {
    final removedTitle = _routines[index].title;
    setState(() {
      _routines.removeAt(index);
      _routineDoneMap.remove(removedTitle);
    });
    _saveRoutines();
    _saveRoutineDone();
  }

  Future<void> _showRoutineMemoDialog(int index) async {
    final memoCtrl = TextEditingController(text: _routines[index].memo);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('メモ編集'),
          content: TextField(
            controller: memoCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'メモ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('保存'),
              onPressed: () {
                setState(() {
                  _routines[index].memo = memoCtrl.text;
                });
                _saveRoutines();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    memoCtrl.dispose();
  }

  Future<void> _showAddRoutineDialog() async {
    await _showRoutineDialog(null);
  }

  Future<void> _showEditRoutineDialog(int index) async {
    await _showRoutineDialog(index);
  }

  Future<void> _showRoutineDialog(int? index) async {
    final isEdit = index != null;
    final titleCtrl = TextEditingController(text: isEdit ? _routines[index].title : '');
    const frequencyOptions = ['毎日', '毎月'];
    String frequency = isEdit && frequencyOptions.contains(_routines[index].frequency)
        ? _routines[index].frequency
        : '毎日';
    String timeSlot = isEdit ? _routines[index].timeSlot : '指定なし';
    List<int> selectedWeekdays = isEdit ? List.from(_routines[index].weekdays) : [];
    DateTime startDate = isEdit ? _routines[index].startDate : DateTime.now();
    int? weekOfMonth = isEdit ? _routines[index].weekOfMonth : null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'ルーティン編集' : 'ルーティン追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'タイトル'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(labelText: '頻度'),
                      items: frequencyOptions
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => frequency = v!),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: timeSlot,
                      decoration: const InputDecoration(labelText: '時間帯'),
                      items: ['指定なし', '朝', '昼', '夜']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => timeSlot = v!),
                    ),
                    const SizedBox(height: 8),
                    if (frequency == '毎月')
                      DropdownButtonFormField<int?>(
                        value: weekOfMonth,
                        decoration: const InputDecoration(labelText: '第何週'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('未指定（日付指定）')),
                          const DropdownMenuItem(value: 1, child: Text('第1週')),
                          const DropdownMenuItem(value: 2, child: Text('第2週')),
                          const DropdownMenuItem(value: 3, child: Text('第3週')),
                          const DropdownMenuItem(value: 4, child: Text('第4週')),
                          const DropdownMenuItem(value: 5, child: Text('第5週')),
                        ],
                        onChanged: (v) => setStateDialog(() => weekOfMonth = v),
                      ),
                    if (frequency == '毎月')
                      const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: List.generate(7, (i) {
                        final weekdayNames = ['日', '月', '火', '水', '木', '金', '土'];
                        return FilterChip(
                          label: Text(weekdayNames[i]),
                          selected: selectedWeekdays.contains(i),
                          onSelected: (selected) {
                            setStateDialog(() {
                              if (selected) {
                                selectedWeekdays.add(i);
                              } else {
                                selectedWeekdays.remove(i);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('開始日: ${startDate.year}/${startDate.month}/${startDate.day}'),
                        ),
                        TextButton(
                          child: const Text('日付選択'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              setStateDialog(() => startDate = d);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(isEdit ? '保存' : '追加'),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isNotEmpty) {
                      // 曜日未選択の場合は全曜日を設定
                      final weekdays = selectedWeekdays.isEmpty 
                          ? [0, 1, 2, 3, 4, 5, 6] 
                          : selectedWeekdays;
                      setState(() {
                        if (isEdit) {
                          _routines[index] = Routine(
                            title: title,
                            weekdays: weekdays,
                            frequency: frequency,
                            timeSlot: timeSlot,
                            startDate: startDate,
                            memo: _routines[index].memo,
                            weekOfMonth: frequency == '毎月' ? weekOfMonth : null,
                          );
                        } else {
                          _routines.add(Routine(
                            title: title,
                            weekdays: weekdays,
                            frequency: frequency,
                            timeSlot: timeSlot,
                            startDate: startDate,
                            weekOfMonth: frequency == '毎月' ? weekOfMonth : null,
                          ));
                        }
                      });
                      _saveRoutines();
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

  void _toggleStart(int index, bool value) {
    setState(() {
      _todos[index].start = value;
      if (value) {
        _todos[index].startDate = DateTime.now();
      } else {
        _todos[index].startDate = null;
      }
    });
    _saveTodos();
  }

  void _resetOldStartChecks() {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    bool hasChanges = false;
    
    for (var todo in _todos) {
      if (todo.start && todo.startDate != null && todo.startDate!.isBefore(todayMidnight)) {
        todo.start = false;
        todo.startDate = null;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      setState(() {});
      _saveTodos();
    }
  }

  void _toggleDone(int index, bool value) {
    setState(() {
      _todos[index].done = value;
      if (value) {
        _todos[index].completedDate = DateTime.now();
      } else {
        _todos[index].completedDate = null;
      }
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _routineShouldRunToday(Routine routine, DateTime today) {
    final start = _dateOnly(routine.startDate);
    if (today.isBefore(start)) return false;
    
    // 曜日チェック（曜日指定がある場合のみ）
    if (routine.weekdays.isNotEmpty) {
      final weekdayIndex = today.weekday % 7; // mon=1...sun=7 -> 0-6
      if (!routine.weekdays.contains(weekdayIndex)) return false;
    }
    
    // 頻度による判定
    switch (routine.frequency) {
      case '毎日':
        return true;
      case '毎週':
        return true; // 曜日チェックは上で済んでいる
      case '毎月':
        if (routine.weekOfMonth != null) {
          // 第何週何曜日かで判定
          return _isNthWeekdayOfMonth(today, routine.weekdays, routine.weekOfMonth!);
        } else {
          // 日付で判定
          return today.day == start.day;
        }
      default:
        return false;
    }
  }

  bool _isNthWeekdayOfMonth(DateTime date, List<int> weekdays, int weekNumber) {
    if (weekdays.isEmpty) return false;
    final weekdayIndex = date.weekday % 7;
    if (!weekdays.contains(weekdayIndex)) return false;
    
    // その月の1日から今日まで、同じ曜日が何回目か数える
    int count = 0;
    for (int day = 1; day <= date.day; day++) {
      final d = DateTime(date.year, date.month, day);
      if (d.weekday % 7 == weekdayIndex) {
        count++;
      }
    }
    return count == weekNumber;
  }

  bool _isRoutineDoneToday(String title, DateTime today) {
    final saved = _routineDoneMap[title];
    if (saved == null) return false;
    try {
      final d = DateTime.parse(saved);
      return d.year == today.year && d.month == today.month && d.day == today.day;
    } catch (_) {
      return false;
    }
  }

  void _toggleRoutineDone(String title, bool value, DateTime today) {
    setState(() {
      if (value) {
        _routineDoneMap[title] = today.toIso8601String();
      } else {
        _routineDoneMap.remove(title);
      }
    });
    _saveRoutineDone();
  }

  Future<void> _showMemoDialog(int index) async {
    final memoCtrl = TextEditingController(text: _todos[index].memo);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('メモ編集'),
          content: TextField(
            controller: memoCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'メモ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('保存'),
              onPressed: () {
                setState(() {
                  _todos[index].memo = memoCtrl.text;
                });
                _saveTodos();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    memoCtrl.dispose();
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
      //   0: 一覧
      //   1: 完了済
      //   2: ルーティン
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