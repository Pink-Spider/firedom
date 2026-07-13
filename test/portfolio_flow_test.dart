import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/engine/engine.dart';
import 'package:firedom/features/simulation/portfolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// S4-2 포트폴리오 구성 플로우 (PRD S4-2, 엔진명세 A11)
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

Future<void> openPortfolio(WidgetTester tester) async {
  await tester.tap(find.text('시뮬레이션'));
  await tester.pumpAndSettle();
  final link = find.text('포트폴리오로 구성하기');
  await tester.ensureVisible(link); // 하단 탭바에 가려질 수 있어 스크롤
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Finder get _portfolioList => find
    .descendant(
        of: find.byType(PortfolioScreen), matching: find.byType(Scrollable))
    .first;

/// S4-2 ListView는 lazy — 화면 밖 위젯은 스크롤해야 빌드된다
Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 150, scrollable: _portfolioList);
  await tester.pumpAndSettle();
}

void main() {
  appTest('S4-2 진입: 균형형 기본 — G8 축약 값(3.80%/16.10%) 표시', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openPortfolio(tester);

    expect(find.text('포트폴리오 구성'), findsOneWidget);
    expect(find.textContaining('합계 100.0%'), findsOneWidget);
    // 규제 프레이밍: "추천" 문구 금지 (PRD S4-2)
    expect(find.textContaining('추천'), findsNothing);

    // G8: r_port=380bp, σ_port=1610bp — 기대수익률은 자산군 비중 위 헤드라인
    await scrollTo(tester, find.text('기대수익률(실질)'));
    expect(find.text('기대수익률(실질)'), findsOneWidget);
    expect(find.text('3.80%'), findsOneWidget);
    expect(find.text('변동성(간이)'), findsOneWidget);
    expect(find.text('16.10%'), findsOneWidget);
  });

  appTest('S4-2 CTA: 이 구성으로 시뮬레이션 → S4 수익률 3.80% 반영', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openPortfolio(tester);

    await scrollTo(tester, find.text('이 구성으로 시뮬레이션'));
    await tester.tap(find.text('이 구성으로 시뮬레이션'));
    await tester.pumpAndSettle();

    // S4 복귀: 기대수익률 슬라이더 라벨이 축약 값으로 갱신
    expect(find.text('3.80%'), findsOneWidget);
  });

  appTest('S4-2 예시 구성 전환: 성장형 → 5.48%', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openPortfolio(tester);

    await tester.tap(find.byKey(const ValueKey('example-growth')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('기대수익률(실질)'));
    expect(find.text('5.48%'), findsOneWidget);
  });

  appTest('S4-2 무료: 비중 슬라이더 잠금 + 배너 탭 → 페이월', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openPortfolio(tester);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('weight-us_sp500')),
    );
    expect(slider.onChanged, isNull, reason: '무료는 비중 편집 잠금');

    await tester.tap(find.textContaining('비중 편집은 프리미엄'));
    await tester.pumpAndSettle();
    expect(find.text('파이어덤 프리미엄'), findsOneWidget);
  });

  appTest('S4-2 프리미엄: 편집 → 합계 깨짐 → CTA 비활성 → 정규화 복구', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db);
      await SettingsStore(db).set(SettingKeys.premiumEntitlement, true);
    });
    await openPortfolio(tester);

    // 편집 가능 + 배너 없음
    expect(find.textContaining('비중 편집은 프리미엄'), findsNothing);
    final sp500 = find.byKey(const ValueKey('weight-us_sp500'));
    expect(tester.widget<Slider>(sp500).onChanged, isNotNull);

    // 비중을 키워 합계를 깨뜨린다
    await tester.drag(sp500, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('합계 100.0%'), findsNothing);

    // 합계 ≠ 100% → 반영 불가 (수용 기준)
    await scrollTo(tester, find.text('이 구성으로 시뮬레이션'));
    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '이 구성으로 시뮬레이션'),
    );
    expect(cta.onPressed, isNull);

    // 자동 정규화 제안 → 복구
    await tester.drag(_portfolioList, const Offset(0, 1200)); // 맨 위로
    await tester.pumpAndSettle();
    await tester.tap(find.text('100%로 맞추기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('합계 100.0%'), findsOneWidget);

    await scrollTo(tester, find.text('이 구성으로 시뮬레이션'));
    final ctaAfter = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '이 구성으로 시뮬레이션'),
    );
    expect(ctaAfter.onPressed, isNotNull);
  });

  appTest('S4-2 가정 보기: 출처·참고치·캐비앳 공개 (수용 기준)', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openPortfolio(tester);

    await scrollTo(tester, find.text('가정 보기'));
    await tester.tap(find.text('가정 보기'));
    await tester.pumpAndSettle();

    expect(find.text('계산에 사용한 가정'), findsOneWidget);
    expect(find.textContaining('USD 기준'), findsOneWidget); // 환변동 캐비앳
    expect(find.textContaining('Damodaran'), findsWidgets); // 출처
    expect(find.textContaining('참고치'), findsWidgets); // 잠정 라벨
  });

  appTest('S4-2 프리미엄: 자산군 삭제 → 행 사라지고 합계 90%', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db);
      await SettingsStore(db).set(SettingKeys.premiumEntitlement, true);
    });
    await openPortfolio(tester);

    // 균형형에 금(gold 10%) 포함 — lazy 리스트라 스크롤해 빌드시킨 뒤 확인
    await scrollTo(tester, find.byKey(const ValueKey('remove-gold')));
    expect(find.byKey(const ValueKey('weight-gold')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('remove-gold')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('weight-gold')), findsNothing);
    // 합계 헤더는 리스트 위쪽 — 스크롤 올려 확인
    await tester.drag(_portfolioList, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(find.textContaining('합계 90.0%'), findsOneWidget); // 금 10% 빠짐
  });

  appTest('S4-2 프리미엄: 자산군 추가 → 시트에서 선택하면 행 생김', (tester) async {
    await pumpApp(tester, seed: (db) async {
      await seedPlan(db);
      await SettingsStore(db).set(SettingKeys.premiumEntitlement, true);
    });
    await openPortfolio(tester);

    // 균형형에 은(silver) 없음
    expect(find.byKey(const ValueKey('weight-silver')), findsNothing);
    await scrollTo(tester, find.byKey(const ValueKey('add-asset')));
    await tester.tap(find.byKey(const ValueKey('add-asset')));
    await tester.pumpAndSettle();

    // 담기지 않은 자산군 시트에서 은 선택 (미검증이라 '· 참고치')
    await tester.tap(find.text('은 · 참고치'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('weight-silver')), findsOneWidget);
  });

  appTest('S4-2 무료: 삭제 버튼·자산군 추가 없음', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openPortfolio(tester);

    expect(find.byKey(const ValueKey('remove-gold')), findsNothing);
    expect(find.byKey(const ValueKey('add-asset')), findsNothing);
  });
}
