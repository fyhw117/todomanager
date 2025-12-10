import 'package:flutter_test/flutter_test.dart';
import 'package:todomanager/main.dart';

void main() {
  testWidgets('アプリ起動でログインボタンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('ログイン'), findsOneWidget);
  });
}