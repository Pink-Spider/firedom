import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  appTest('첫 실행 시 온보딩 1문항(나이)부터 시작한다', (tester) async {
    await pumpApp(tester);

    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.textContaining('나이'), findsWidgets);
  });
}
