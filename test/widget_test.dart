import 'package:firedom/app/app.dart';
import 'package:firedom/data/prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('첫 실행 시 온보딩 1문항(나이)부터 시작한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const FiredomApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.textContaining('나이'), findsWidgets);
  });
}
