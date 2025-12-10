import 'package:flutter/material.dart';
import 'package:todomanager/todo_list_screen.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});
  // Formのkeyを指定する場合は<FormState>としてGlobalKeyを定義する
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        // Formのkeyに指定する
        key: _formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TODO管理アプリ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  // メールアドレス用のバリデーション
                  validator: (String? value) {
                    // メールアドレスが入力されていない場合
                    if (value?.isEmpty == true) {
                      // 問題があるときはメッセージを返す
                      return 'メールアドレスを入力して下さい';
                    }else if(!(value! == "0117")){
                      return '正しいメールアドレスを入力して下さい';
                    }else{
                    // 問題ないときはnullを返す
                    return null;
                    }
                  }
                ),
                SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  // パスワード用のバリデーション
                  validator: (String? value) {
                    // パスワードが入力されていない場合
                    if (value?.isEmpty == true) {
                      // 問題があるときはメッセージを返す
                      return 'パスワードを入力して下さい';
                    }else if(!(value! == '0117')){
                      return '正しいパスワードを入力して下さい';
                    }
                    // 問題ないときはnullを返す
                    return null;
                  },
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // ログインボタンをタップしたときの処理
                    onPressed: () => _onSignIn(context),
                    child: Text('ログイン'),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // 新規登録ボタンをタップしたときの処理（未実装の旨を表示）
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('エラー'),
                          content: const Text('新規登録機能は未実装です'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('OK')),
                          ],
                        ),
                      );
                    },
                    child: Text('新規登録'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSignIn(BuildContext context) {
    // 入力内容を確認する
    if (_formKey.currentState?.validate() != true) {
    return;
    }

    // 画像一覧画面に切り替え
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TodoListScreen(),
      ),
    );
  }

}