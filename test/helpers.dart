import 'package:drift/native.dart';
import 'package:firedom/app/app.dart';
import 'package:firedom/data/bootstrap.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/db/providers.dart';
import 'package:firedom/data/home_widget_sync.dart';
import 'package:firedom/data/prefs.dart';
import 'package:firedom/features/lock/app_lock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  // Riverpod 3은 Override 타입을 공개하지 않아 Object로 받고 cast()로 전달
  List<Object> overrides = const [],
}) async {
  // 테스트 기기 언어는 en_US라 ko로 고정한다 — 기존 테스트의 한국어 finder 유지.
  // 영어·일본어 화면 검증은 pumpApp 뒤 platformDispatcher.localeTestValue로 바꾼다
  tester.platformDispatcher.localeTestValue = const Locale('ko');
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  PackageInfo.setMockInitialValues(
    appName: 'firedom',
    packageName: 'app.firedom.firedom',
    version: '1.0.0',
    buildNumber: '10',
    buildSignature: '',
  );
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (seed != null) await seed(db);
  final bootstrap = await bootstrapApp(db, prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        hasActivePlanAtLaunchProvider.overrideWithValue(
            bootstrap.hasActivePlan),
        biometricLockAtLaunchProvider.overrideWithValue(
            bootstrap.biometricLockEnabled),
        // 위젯 동기화는 플랫폼 채널이라 테스트에서 no-op
        homeWidgetSyncProvider.overrideWithValue((_) async {}),
        ...overrides.cast(),
      ],
      child: const FiredomApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
