import 'package:drift/native.dart';
import 'package:firedom/app/app.dart';
import 'package:firedom/data/bootstrap.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/db/providers.dart';
import 'package:firedom/data/prefs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// pumpApp을 쓰는 위젯 테스트용 testWidgets 래퍼.
///
/// 테스트 종료 전에 위젯 트리를 내려 drift 스트림 구독을 해제하고,
/// drift의 스트림 정리 지연 타이머(수백 ms)를 소진시킨다 —
/// 그렇지 않으면 "A Timer is still pending" 불변식에 걸린다.
void appTest(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    try {
      await callback(tester);
    } finally {
      // 실패 시에도 반드시 트리를 내려 스트림 구독을 해제해야
      // 남은 타이머/DB 정리가 다음 테스트를 막지 않는다
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }
  });
}

/// 앱 전체를 in-memory DB + mock prefs로 띄운다.
/// [seed]로 계획/스냅샷을 미리 넣을 수 있다.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
  Future<void> Function(AppDatabase db)? seed,
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (seed != null) await seed(db);
  final hasPlan = await bootstrapApp(db, prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        hasActivePlanAtLaunchProvider.overrideWithValue(hasPlan),
      ],
      child: const FiredomApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
