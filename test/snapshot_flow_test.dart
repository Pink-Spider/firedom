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

Future<Plan> seedPlan(AppDatabase db, {required int startedYm}) {
  return PlanRepository(db).createPlan(
    input: _g1,
    birthYm: birthYmFromAge(_g1.age0, startedYm),
    startedYm: startedYm,
  );
}

Future<void> openFlow(WidgetTester tester) async {
  await tester.tap(find.text('기록하기'));
  await tester.pumpAndSettle();
}

Future<void> scrollFlowTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  appTest('S8 첫 기록: 기본 6항목 → 저장 → 결과 리빌 → 홈 반영', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: nowYm());
    });
    await openFlow(tester);

    // 첫 달 항목 셋업 (PRD S8) — 라벨·자산군 헬퍼가 같은 텍스트일 수 있어 키로 확인
    for (final name in ['예금', '주식', '연금계좌', '부동산', '대출', '기타']) {
      expect(find.byKey(ValueKey('amount-$name')), findsOneWidget);
    }

    await tester.enterText(
        find.byKey(const ValueKey('amount-예금')), '150000000');
    await tester.pump();

    await scrollFlowTo(tester, find.byKey(const ValueKey('income-field')));
    await tester.enterText(
        find.byKey(const ValueKey('income-field')), '5000000');
    await tester.enterText(
        find.byKey(const ValueKey('expense-field')), '3000000');
    await tester.pump();

    await scrollFlowTo(tester, find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    // 결과 리빌: 순자산 카운트업 완료 후 최종 값
    expect(find.textContaining('기록 완료'), findsOneWidget);
    expect(find.text('1억 5,000만원'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget); // (500만−300만)/500만
    expect(find.textContaining('다음 기록부터'), findsOneWidget); // 첫 기록

    await tester.tap(find.text('홈으로'));
    await tester.pumpAndSettle();

    // 홈: 이번 달 기록됨 → 기록 유도 카드 없음
    expect(find.textContaining('자산을 기록해볼까요'), findsNothing);
  });

  appTest('S8 전월 복사: 지난달 값이 기본값, 수정 후 증감 표시', (tester) async {
    final lastMonth = ymAddMonths(nowYm(), -1);
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: lastMonth);
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      await repo.saveSnapshot(
        ym: lastMonth,
        amountsByAccountId: {accounts.first.id: 100000000},
        income: 5000000,
        expense: 3000000,
      );
    });
    await openFlow(tester);

    // 전월 값 복사 (PRD S8 수용 기준)
    final depositField =
        tester.widget<TextField>(find.byKey(const ValueKey('amount-예금')));
    expect(depositField.controller!.text, '100,000,000');

    await tester.enterText(
        find.byKey(const ValueKey('amount-예금')), '120000000');
    await tester.pump();
    await scrollFlowTo(tester, find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    // 결과 리빌: 전월 대비 +2,000만원, 궤도 배지(2번째 기록)
    expect(find.text('전월 대비 +2,000만원'), findsOneWidget);
    expect(find.textContaining('앞서는 중'), findsOneWidget);
  });

  appTest('S8 draft 보존: 중간 이탈 후 재진입 시 입력값 복원', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: nowYm());
    });
    await openFlow(tester);

    await tester.enterText(
        find.byKey(const ValueKey('amount-주식')), '7000000');
    await tester.pump();

    // 저장 없이 뒤로 (한국어 로케일이라 pageBack의 'Back' 툴팁 탐색이 안 됨)
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await openFlow(tester);
    final equityField =
        tester.widget<TextField>(find.byKey(const ValueKey('amount-주식')));
    expect(equityField.controller!.text, '7,000,000');
  });

  appTest('S8 항목 추가: 이름·자산군 입력 → 목록에 나타남', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: nowYm());
    });
    await openFlow(tester);

    await scrollFlowTo(tester, find.text('항목 추가'));
    await tester.tap(find.text('항목 추가'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'ISA');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('amount-ISA')), findsOneWidget);
  });

  appTest('S8 과거 월 소급: 이전 달로 이동해 기록 가능', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: ymAddMonths(nowYm(), -2));
    });
    await openFlow(tester);

    final lastMonth = ymAddMonths(nowYm(), -1);
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text(formatYm(lastMonth)), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('amount-예금')), '50000000');
    await tester.pump();
    await scrollFlowTo(tester, find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('${lastMonth % 100}월 기록 완료!'), findsOneWidget);
    expect(find.text('5,000만원'), findsOneWidget);
  });
}
