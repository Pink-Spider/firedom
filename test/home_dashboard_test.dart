import 'dart:convert';

import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// G1과 동일 가정의 계획 (tF=231)
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

void main() {
  appTest('S3: 계획만 있으면 D-day + 기록 유도 + 첫 기록 안내', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: nowYm());
    });

    expect(find.text('재정적 자유까지 19년 3개월'), findsOneWidget);
    expect(find.textContaining('자산을 기록해볼까요'), findsOneWidget);
    expect(find.textContaining('첫 기록을 남기면'), findsOneWidget);
    expect(find.textContaining('FIRE 진행률'), findsOneWidget);
  });

  appTest('S3: 스냅샷 2개, 궤도보다 2개월 앞 → 앞섬 배지 + 저축률', (tester) async {
    final startedYm = ymAddMonths(nowYm(), -2);
    final curve = solvePlan(_g1).assetsByMonth;

    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: startedYm);
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      final deposit = accounts.first.id;
      // 경과 1개월 시점에 계획 3개월 지점 자산 → +2개월 앞섬
      await repo.saveSnapshot(
        ym: ymAddMonths(startedYm, 1),
        amountsByAccountId: {deposit: curve[3]},
        income: 5000000,
        expense: 3000000,
      );
      // 경과 2개월(이번 달) 시점에 계획 4개월 지점 자산
      await repo.saveSnapshot(
        ym: ymAddMonths(startedYm, 2),
        amountsByAccountId: {deposit: curve[4]},
        income: 5000000,
        expense: 2500000,
      );
    });

    expect(find.text('계획보다 2개월 앞서는 중'), findsOneWidget);
    // 이번 달 기록 완료 → 기록 유도 카드 없음
    expect(find.textContaining('자산을 기록해볼까요'), findsNothing);

    // 아래 영역은 스크롤해야 보인다
    await tester.scrollUntilVisible(
        find.textContaining('이번 달 기록 완료'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('이번 달 기록 완료'), findsOneWidget);
    // 저축률 (500만−250만)/500만 = 50%
    expect(find.text('50%'), findsOneWidget);
  });

  appTest('S3: 스냅샷 1개면 궤도 비교 대신 안내 문구', (tester) async {
    final startedYm = ymAddMonths(nowYm(), -1);

    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: startedYm);
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      await repo.saveSnapshot(
        ym: startedYm,
        amountsByAccountId: {accounts.first.id: 100000000},
      );
    });

    expect(find.textContaining('2번째 기록부터'), findsOneWidget);
    expect(find.textContaining('계획보다'), findsNothing);
  });

  appTest('S3: 금액 가림 토글 — 탭 1번으로 ●●● 처리', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db, startedYm: nowYm());
    });

    expect(find.textContaining('●●●'), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.textContaining('●●●'), findsWidgets);

    // 다시 탭하면 해제
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();
    expect(find.textContaining('●●●'), findsNothing);
  });

  appTest('부트스트랩: 레거시(prefs) 계획이 plans 테이블로 이관', (tester) async {
    final legacy = jsonEncode({
      'age0': 35,
      'currentAssets': 100000000,
      'monthlySaving': 2000000,
      'realReturnBp': 400,
      'monthlySpendRetire': 3000000,
      'swrBp': 400,
      'lifeExpectancy': 90,
      'volatilityBp': 1200,
    });
    final db = await pumpApp(tester, prefsValues: {'active_plan_v0': legacy});

    // 홈부터 시작 + DB에 활성 계획 존재
    expect(find.text('재정적 자유까지 19년 3개월'), findsOneWidget);
    expect(await PlanRepository(db).getActivePlan(), isNotNull);

    // 레거시 키는 제거됨
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_plan_v0'), isNull);
  });
}
