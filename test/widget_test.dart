import 'package:firedom/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱 실행 시 온보딩 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FiredomApp()));
    await tester.pumpAndSettle();

    expect(find.textContaining('온보딩'), findsOneWidget);
  });
}
