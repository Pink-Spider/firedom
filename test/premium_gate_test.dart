import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/engine/engine.dart';
import 'package:firedom/features/simulation/monte_carlo_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _g1 = PlanInput(
  age0: 35,
  currentAssets: 100000000,
  monthlySaving: 2000000,
  realReturnBp: 400,
  monthlySpendRetire: 3000000,
);

Future<void> seedPlan(AppDatabase db) async {
  final ym = nowYm();
  await PlanRepository(db).createPlan(
    input: _g1,
    birthYm: birthYmFromAge(_g1.age0, ym),
    startedYm: ym,
  );
}

final _syncRunner = monteCarloRunnerProvider.overrideWithValue(
  (request) async => runMonteCarlo(MonteCarloRequest(
    plan: request.plan,
    retirementMonth: request.retirementMonth,
    runs: 300,
    seed: 42,
  )),
);

Future<void> runTeaser(WidgetTester tester) async {
  await tester.tap(find.text('시뮬레이션'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('성공 확률 계산하기'), 200,
      scrollable: find.byType(Scrollable).first);
  // scrollUntilVisible은 cacheExtent에서 빌드만 되면 멈춘다 — 실제 뷰포트 안으로
  await tester.ensureVisible(find.text('성공 확률 계산하기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('성공 확률 계산하기'));
  await tester.pumpAndSettle();
}

void main() {
  appTest('무료: 상세 분포 🔒 → 페이월, 구매는 연동 준비 안내', (tester) async {
    await pumpApp(tester,
        seed: (db) async => seedPlan(db), overrides: [_syncRunner]);
    await runTeaser(tester);

    await tester.ensureVisible(find.text('상세 분포 보기 🔒'));
    await tester.tap(find.text('상세 분포 보기 🔒'));
    await tester.pumpAndSettle();
    expect(find.text('파이어덤 프리미엄'), findsOneWidget);

    // 혜택 목록: 제공 중인 기능만 체크, 미출시는 '출시 예정' (오인 구매 방지)
    expect(find.text('포트폴리오 비중 자유 편집'), findsOneWidget);
    expect(find.text('출시 예정'), findsWidgets);
    // 연간 우선 표기
    expect(find.textContaining('연 39,000원'), findsOneWidget);

    await tester.tap(find.text('구독 시작하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('결제 연동 준비 중'), findsOneWidget);
  });

  appTest('프리미엄: 상세 분포 화면 — 밴드 p10/p50/p90 + 고갈 분포', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db);
      await SettingsStore(db).set(SettingKeys.premiumEntitlement, true);
    }, overrides: [
      _syncRunner,
    ]);
    await runTeaser(tester);

    expect(find.text('상세 분포 보기'), findsOneWidget); // 🔒 없음
    await tester.ensureVisible(find.text('상세 분포 보기'));
    await tester.tap(find.text('상세 분포 보기'));
    await tester.pumpAndSettle();

    expect(find.text('성공 확률 상세'), findsOneWidget);
    expect(find.text('중간 (p50)'), findsOneWidget);
    expect(find.textContaining('하위 10%'), findsOneWidget);
    expect(find.text('자산 고갈 나이 분포'), findsOneWidget);
    expect(find.textContaining('투자 자문이 아닙니다'), findsOneWidget);
  });

  appTest('설정: 디버그 프리미엄 토글 → 구독 상태 표시 갱신', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('debug-premium-switch')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('debug-premium-switch')));
    await tester.pumpAndSettle();

    expect(find.textContaining('이용 중 🎉'), findsOneWidget);
  });
}
