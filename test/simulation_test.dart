import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/scenario_repository.dart';
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

Future<Plan> seedPlan(AppDatabase db) {
  final ym = nowYm();
  return PlanRepository(db).createPlan(
    input: _g1,
    birthYm: birthYmFromAge(_g1.age0, ym),
    startedYm: ym,
  );
}

/// isolate 대신 동기 실행 (runs 축소) — 위젯 테스트의 FakeAsync에서
/// compute()의 실제 isolate는 완료를 기다릴 수 없다.
final _syncRunnerOverride = monteCarloRunnerProvider.overrideWithValue(
  (request) async => runMonteCarlo(MonteCarloRequest(
    plan: request.plan,
    retirementMonth: request.retirementMonth,
    runs: 200,
    seed: 7,
  )),
);

Future<void> openSimulationTab(WidgetTester tester) async {
  await tester.tap(find.text('시뮬레이션'));
  await tester.pumpAndSettle();
}

void main() {
  appTest('하단 탭: 홈 ↔ 시뮬레이션 전환, S4 기본 결과 표시 (G1 → 54세)', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));

    expect(find.textContaining('재정적 자유까지'), findsOneWidget); // 홈
    await openSimulationTab(tester);

    expect(find.textContaining('계획에 반영되지 않아요'), findsOneWidget);
    expect(find.text('FIRE 나이 54세'), findsOneWidget);

    // 홈으로 복귀
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.textContaining('재정적 자유까지'), findsOneWidget);
  });

  appTest('S4 슬라이더: 저축 최대(1,000만) → FIRE 나이 40세로 즉시 재계산', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openSimulationTab(tester);

    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('saving-slider')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.drag(
        find.byKey(const ValueKey('saving-slider')), const Offset(600, 0));
    await tester.pumpAndSettle();

    // ListView가 lazy라 헤드라인으로 다시 스크롤해서 확인
    await tester.scrollUntilVisible(find.textContaining('FIRE 나이'), -200,
        scrollable: find.byType(Scrollable).first);
    // 저축 1,000만/월 → tF=70개월 → 35 + 5 = 40세
    expect(find.text('FIRE 나이 40세'), findsOneWidget);
  });

  appTest('S4 몬테카를로: isolate 러너 호출 → 정확한 성공 확률 티저 + 🔒 페이월', (tester) async {
    await pumpApp(
      tester,
      seed: (db) async => seedPlan(db),
      overrides: [_syncRunnerOverride],
    );
    await openSimulationTab(tester);

    await tester.scrollUntilVisible(find.text('성공 확률 계산하기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('성공 확률 계산하기'));
    await tester.pumpAndSettle();

    // 티저는 정확한 값 (가짜 블러 금지) — 시드 고정이라 결정론적
    final expected = runMonteCarlo(MonteCarloRequest(
      plan: _g1,
      retirementMonth: 231,
      runs: 200,
      seed: 7,
    ));
    final pct = (expected.successRate * 100).toStringAsFixed(0);
    expect(find.text('이 계획의 성공 확률 $pct%'), findsOneWidget);

    // 상세 분포는 유료 훅 → 페이월 시트
    await tester.tap(find.text('상세 분포 보기 🔒'));
    await tester.pumpAndSettle();
    expect(find.text('파이어덤 프리미엄'), findsOneWidget);
    expect(find.textContaining('월 4,900원'), findsOneWidget);
  });

  appTest('S4 시나리오 저장 1개 + 불러오기', (tester) async {
    final db = await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openSimulationTab(tester);

    await tester.scrollUntilVisible(find.text('시나리오 저장'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('시나리오 저장'));
    await tester.pumpAndSettle();

    expect(find.textContaining('시나리오를 저장했어요'), findsOneWidget);
    expect(find.text('불러오기'), findsOneWidget);

    // 무료 1개 제한: 다시 저장해도 1개만 유지
    await tester.tap(find.text('시나리오 저장'));
    await tester.pumpAndSettle();
    final scenario = await ScenarioRepository(db).loadSingle();
    expect(scenario, isNotNull);
    final rows = await db.select(db.scenarios).get();
    expect(rows.where((r) => r.deletedAt == null).length, 1);
  });
}
