import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// 다국어 누락 회귀 테스트 — en·ja 설정으로 주요 화면을 열었을 때
/// 화면에 한글이 한 글자도 남아 있지 않아야 한다 (하드코딩 문구 누락 감지).
/// 언어 전환은 실제 경로(settings.locale → localeProvider → MaterialApp)로 한다.
void main() {
  final hangul = RegExp(r'[가-힣]');

  void expectNoKorean(WidgetTester tester, String screen) {
    final leaked = <String>[];
    for (final element in find.byType(Text).evaluate()) {
      final text = element.widget as Text;
      final data = text.data ?? text.textSpan?.toPlainText() ?? '';
      if (hangul.hasMatch(data)) leaked.add(data);
    }
    for (final element in find.byType(RichText).evaluate()) {
      final data = (element.widget as RichText).text.toPlainText();
      if (hangul.hasMatch(data)) leaked.add(data);
    }
    expect(leaked, isEmpty, reason: '$screen 화면에 한국어 누락: $leaked');
  }

  Future<void> seedPlanAndSnapshot(AppDatabase db, String locale,
      {required String currency}) async {
    final store = SettingsStore(db);
    await store.set(SettingKeys.locale, locale);
    await store.set(SettingKeys.currency, currency);
    final ym = nowYm();
    await PlanRepository(db).createPlan(
      input: const PlanInput(
        age0: 35,
        currentAssets: 10000000,
        monthlySaving: 200000,
        realReturnBp: 400,
        monthlySpendRetire: 300000,
      ),
      birthYm: birthYmFromAge(35, ym),
      startedYm: ym,
    );
    final repo = SnapshotRepository(db);
    final accounts = await repo.ensureDefaultAccounts(
        names: const ['A', 'B', 'C', 'D', 'E', 'F']);
    await repo.saveSnapshot(
      ym: ym,
      amountsByAccountId: {accounts.first.id: 12000000},
    );
  }

  for (final (locale, currency) in [('en', 'USD'), ('ja', 'JPY')]) {
    appTest('[$locale] 온보딩 화면에 한국어 없음', (tester) async {
      await pumpApp(tester, seed: (db) async {
        await SettingsStore(db).set(SettingKeys.locale, locale);
      });
      expectNoKorean(tester, '온보딩');
      expect(find.text('Firedom'), findsNothing, reason: '브랜드명은 앱바가 아니라 OS 아이콘에만');
    });

    appTest('[$locale/$currency] 홈 → 시뮬레이션 → 자산 → 설정 → 기록 화면에 한국어 없음',
        (tester) async {
      await pumpApp(tester,
          seed: (db) => seedPlanAndSnapshot(db, locale, currency: currency));
      expectNoKorean(tester, '홈');

      await tester.tap(find.byIcon(Icons.query_stats));
      await tester.pumpAndSettle();
      expectNoKorean(tester, '시뮬레이션');

      await tester.tap(find.byIcon(Icons.pie_chart_outline));
      await tester.pumpAndSettle();
      expectNoKorean(tester, '자산');

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expectNoKorean(tester, '설정');

      await tester.tap(find.byType(BackButton)); // pageBack은 'Back' 툴팁(영어) 의존
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expectNoKorean(tester, '목표 설정');

      await tester.tap(find.byType(BackButton)); // pageBack은 'Back' 툴팁(영어) 의존
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expectNoKorean(tester, '기록');
    });
  }
}
