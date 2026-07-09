import 'package:firedom/core/ym.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
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

void main() {
  appTest('기록 저장 → 결과 리빌 축하 → 홈 배너 (중복 기록 없음)', (tester) async {
    final db = await pumpApp(tester, seed: (db) async {
      final ym = nowYm();
      await PlanRepository(db).createPlan(
        input: _g1,
        birthYm: birthYmFromAge(_g1.age0, ym),
        startedYm: ym,
      );
    });

    // 기록: 예금 1.5억 → 5,000만·1억 돌파 + 첫 기록
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('amount-예금')), '150000000');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('저장'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    // 결과 리빌: 축하 카드
    await tester.scrollUntilVisible(find.text('마일스톤 달성'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('순자산 5,000만원 돌파! 🎉'), findsOneWidget);
    expect(find.text('순자산 1억 돌파! 🎉'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('홈으로'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('홈으로'));
    await tester.pumpAndSettle();

    // 홈 배너 (최신 기록 월 달성분만)
    expect(find.textContaining('돌파! 🎉'), findsOneWidget);
    expect(find.text('외 1개 달성'), findsOneWidget);

    // 같은 달 재저장 → 중복 기록 없음
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('저장'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final rows = await db.select(db.milestones).get();
    final keys = rows.map((r) => r.milestoneKey).toList();
    expect(keys.where((k) => k == 'net_worth_100m').length, 1);
  });
}
