import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// S10 화면 테마 + S10-2 구독 관리 (PRD)
const _g1 = PlanInput(
  age0: 35,
  currentAssets: 100000000,
  monthlySaving: 2000000,
  realReturnBp: 400,
  monthlySpendRetire: 3000000,
);

Future<Plan> seedPlan(AppDatabase db) {
  final ym = nowYm();
  return PlanRepository(db).createPlan(
    input: _g1,
    birthYm: birthYmFromAge(_g1.age0, ym),
    startedYm: ym,
  );
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

Future<void> scrollSettingsTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 150,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  appTest('S10 테마: 기본 시스템 → 다크 선택 시 즉시 반영 + 설정 저장', (tester) async {
    final db = await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openSettings(tester);

    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);
    expect(app().darkTheme, isNotNull);

    await scrollSettingsTo(
        tester, find.byKey(const ValueKey('theme-mode-dropdown')));
    await tester.tap(find.byKey(const ValueKey('theme-mode-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다크').last);
    await tester.pumpAndSettle();

    expect(app().themeMode, ThemeMode.dark); // 즉시 전 화면 반영 (수용 기준)
    expect(
      await SettingsStore(db).get<String>(SettingKeys.themeMode),
      'dark', // 재실행 시 유지
    );
  });

  appTest('S10-2: 미구독자 프리미엄 타일 → 페이월', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openSettings(tester);

    await scrollSettingsTo(tester, find.text('파이어덤 프리미엄'));
    await tester.tap(find.text('파이어덤 프리미엄'));
    await tester.pumpAndSettle();

    // 페이월이 열렸는지 — 테스트 환경은 RevenueCat 미구성이라 가격 대신 재시도 버튼이 뜬다
    expect(find.byKey(const ValueKey('paywall-reload-prices')), findsOneWidget);
    expect(find.textContaining('7일 무료 체험'), findsOneWidget);
    expect(find.text('구독 관리'), findsNothing);
  });

  appTest('S10-2: 구독자 프리미엄 타일 → 구독 관리 화면 + 복원', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db);
      await SettingsStore(db).set(SettingKeys.premiumEntitlement, true);
    });
    await openSettings(tester);

    await scrollSettingsTo(tester, find.text('파이어덤 프리미엄'));
    await tester.tap(find.text('파이어덤 프리미엄'));
    await tester.pumpAndSettle();

    expect(find.text('구독 관리'), findsOneWidget);
    expect(find.text('파이어덤 프리미엄 이용 중 🎉'), findsOneWidget);
    expect(find.text('스토어에서 구독 관리'), findsOneWidget);
    expect(find.textContaining('해지해도 남은 기간까지'), findsOneWidget);

    // 복원: 스토어 연동 전이라 실패 안내 (EntitlementService.restore → false)
    await tester.tap(find.text('구매 복원'));
    await tester.pumpAndSettle();
    expect(find.textContaining('복원할 구매를 찾지 못했어요'), findsOneWidget);
  });
}
