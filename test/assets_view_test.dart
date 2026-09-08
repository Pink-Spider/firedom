import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
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

/// 주식 6,000만 + 예금 4,000만 + 대출 −2,000만 스냅샷 시드
Future<AppDatabase> seedWithSnapshot(
  WidgetTester tester, {
  int? income,
  int? expense,
}) {
  return pumpApp(tester, seed: (db) async {
    final ym = nowYm();
    await PlanRepository(db).createPlan(
      input: _g1,
      birthYm: birthYmFromAge(_g1.age0, ym),
      startedYm: ym,
    );
    final repo = SnapshotRepository(db);
    final accounts = await repo.ensureDefaultAccounts();
    final deposit = accounts[0].id; // 예금 (cash)
    final equity = accounts[1].id; // 주식 (equity)
    final loan = accounts[4].id; // 대출 (부채)
    await repo.saveSnapshot(
      ym: ym,
      amountsByAccountId: {
        equity: 60000000,
        deposit: 40000000,
        loan: -20000000,
      },
      income: income,
      expense: expense,
    );
  });
}

Future<void> openAssetsTab(WidgetTester tester) async {
  await tester.tap(find.text('자산'));
  await tester.pumpAndSettle();
}

void main() {
  appTest('S6 자산배분: 도넛 + 자산군별 비중 (부채는 제외)', (tester) async {
    await seedWithSnapshot(tester);
    await openAssetsTab(tester);

    // 주식 60% / 현금 40% (부채 −2,000만은 도넛에서 제외)
    expect(find.text('주식'), findsOneWidget);
    expect(find.text('현금/예금'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.textContaining('6,000만'), findsOneWidget);
  });

  appTest('S6 목표 배분: 설정 후 편차 %p 표시 (사실 표시만)', (tester) async {
    await seedWithSnapshot(tester);
    await openAssetsTab(tester);

    await tester.scrollUntilVisible(find.text('목표 배분 설정'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('목표 배분 설정'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('target-equity')), '50');
    await tester.enterText(find.byKey(const ValueKey('target-cash')), '50');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    // 실제 60/40 vs 목표 50/50 → +10%p / −10%p
    expect(find.text('목표 50% · +10%p'), findsOneWidget);
    expect(find.text('목표 50% · −10%p'), findsOneWidget);
  });

  appTest('S6 현금흐름: 소득/지출 막대 + 저축률', (tester) async {
    await seedWithSnapshot(tester, income: 5000000, expense: 3000000);
    await openAssetsTab(tester);

    await tester.tap(find.text('현금흐름'));
    await tester.pumpAndSettle();

    expect(find.text('소득'), findsOneWidget);
    expect(find.text('지출'), findsOneWidget);
    expect(find.textContaining('저축 200만원'), findsOneWidget);
    expect(find.text('저축률 40%'), findsOneWidget);
  });

  appTest('S6 현금흐름: 소득/지출 미입력이면 안내', (tester) async {
    await seedWithSnapshot(tester);
    await openAssetsTab(tester);

    await tester.tap(find.text('현금흐름'));
    await tester.pumpAndSettle();

    expect(find.textContaining('소득/지출을 함께 적으면'), findsOneWidget);
  });

  appTest('S6 연금·세제 탭은 노출하지 않는다 (미구현 기능에 결제 유도 금지)',
      (tester) async {
    await seedWithSnapshot(tester);
    await openAssetsTab(tester);

    expect(find.textContaining('연금'), findsNothing);
    expect(find.text('자산배분'), findsOneWidget);
    expect(find.text('현금흐름'), findsOneWidget);
  });
}
