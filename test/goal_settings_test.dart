import 'package:drift/native.dart';
import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
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

Future<Plan> seedPlan(AppDatabase db) {
  final ym = nowYm();
  return PlanRepository(db).createPlan(
    input: _g1,
    birthYm: birthYmFromAge(_g1.age0, ym),
    startedYm: ym,
  );
}

void main() {
  test('revisePlan: 같은 revision_group에 새 리비전, 활성은 1개', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PlanRepository(db);
    final first = await seedPlan(db);

    final revised = await repo.revisePlan(
      base: first,
      input: _g1.copyWith(swrBp: 350),
      fireType: 'lean',
    );

    expect(revised.revisionGroup, first.revisionGroup);
    expect(revised.swrBp, 350);
    expect(revised.fireType, 'lean');
    expect(revised.startedYm, first.startedYm); // 궤도 기준점 유지
    expect(revised.currentAssets, first.currentAssets);

    final active = await repo.getActivePlan();
    expect(active!.id, revised.id);

    final revisions = await repo.watchRevisions(first.revisionGroup).first;
    expect(revisions.length, 2);
    expect(revisions.where((p) => p.isActive).length, 1);
  });

  appTest('S7: 미리보기 표시 + SWR 변경 저장 → 홈 궤도 반영 + 리비전 기록', (tester) async {
    final db = await pumpApp(tester, seed: (db) async => seedPlan(db));

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // 미리보기: G1 → 54세
    expect(find.text('FIRE 나이 54세'), findsOneWidget);

    // SWR 4.0% → 5.0% (슬라이더 오른쪽 끝) → tF=201... 아니라 720000000 목표
    await tester.drag(
        find.byKey(const ValueKey('swr-slider')), const Offset(400, 0));
    await tester.pumpAndSettle();
    // SWR 5%면 목표 7.2억 → tF 201개월 → 35+16 = 51세
    expect(find.text('FIRE 나이 51세'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('저장하기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    // 홈 복귀 + 반영: 남은 기간이 51세 기준으로 갱신
    expect(find.textContaining('재정적 자유까지 16년'), findsOneWidget);

    final repo = PlanRepository(db);
    final active = await repo.getActivePlan();
    expect(active!.swrBp, 500);
    // FakeAsync 안에서는 watch 스트림 .first 대기가 멈추므로 get 사용
    final revisions = await repo.getRevisions(active.revisionGroup);
    expect(revisions.length, 2);
  });

  appTest('S7: 국민연금 입력 → 브릿지 분리 계산 표시 + 단축 효과', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('국민연금 반영'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('nps-amount-field')), '1000000');
    await tester.pump();

    // 분리 계산 (PRD S7 수용 기준): 수령 전 전액 / 수령 후 생활비−연금
    await tester.scrollUntilVisible(find.textContaining('수령 전'), -300,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('수령 전(~64세): 월 300만원 (생활비 전액)'),
        findsOneWidget);
    expect(find.textContaining('수령 후(65세~): 월 200만원'), findsOneWidget);
    expect(find.textContaining('앞당겨져요'), findsOneWidget);
  });
}
