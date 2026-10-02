import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
import 'package:firedom/features/simulation/monte_carlo_runner.dart';
import 'package:firedom/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';

/// 스토어 스크린샷 촬영 — 실제 기기 해상도로 앱을 띄우고 화면을 담는다.
///
/// 언어·통화는 앱 설정(settings 테이블)으로 바꾼다. 시뮬레이터 언어를 건드리지 않아도
/// 되고, 같은 데이터로 세 언어를 똑같이 찍을 수 있다.
///   --dart-define=SHOT_LOCALE=en --dart-define=SHOT_CURRENCY=USD
/// 데이터는 in-memory DB에 심어 매번 동일한 화면이 나오게 한다 (실기기 데이터 불필요).
const _locale = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'ko');
const _currency = String.fromEnvironment('SHOT_CURRENCY', defaultValue: 'KRW');
/// 화면마다 머무는 시간 — 바깥 캡처 루프와 맞춘다
const _hold = Duration(seconds: 8);

/// 통화별 "사람에게 자연스러운" 시연 금액 (최소 단위).
/// KRW·JPY는 원/엔 그대로, USD는 센트.
const _demo = {
  'KRW': (assets: 120000000, saving: 2000000, spend: 2500000, income: 4800000,
      expense: 2800000, netWorth: 138000000),
  'USD': (assets: 9000000, saving: 150000, spend: 200000, income: 360000,
      expense: 210000, netWorth: 10400000),
  'JPY': (assets: 12000000, saving: 200000, spend: 250000, income: 480000,
      expense: 280000, netWorth: 13800000),
};

Future<void> _seed(AppDatabase db) async {
  final store = SettingsStore(db);
  await store.set(SettingKeys.locale, _locale);
  await store.set(SettingKeys.currency, _currency);
  final d = _demo[_currency]!;

  final startedYm = ymAddMonths(nowYm(), -7);
  await PlanRepository(db).createPlan(
    input: PlanInput(
      age0: 36,
      currentAssets: d.assets,
      monthlySaving: d.saving,
      realReturnBp: 450,
      monthlySpendRetire: d.spend,
      volatilityBp: 1200,
    ),
    birthYm: birthYmFromAge(36, startedYm),
    startedYm: startedYm,
  );

  // 최근 6개월 기록 — 궤도 차트와 저축률 추이가 보이도록 조금씩 증가
  final repo = SnapshotRepository(db);
  // 기본 항목 이름도 현재 언어로 — 실제 앱이 기록 화면에서 넘기는 것과 같은 l10n 문구다.
  // 그냥 ensureDefaultAccounts()를 부르면 한국어 기본 시드가 들어가 영어 화면에 한글이 남는다.
  final l10n = lookupAppLocalizations(Locale(_locale));
  final accounts = await repo.ensureDefaultAccounts(names: [
    l10n.snapDefaultDeposits,
    l10n.snapDefaultStocks,
    l10n.snapDefaultPension,
    l10n.snapDefaultRealEstate,
    l10n.snapDefaultLoans,
    l10n.snapDefaultOther,
  ]);
  for (var i = 6; i >= 0; i--) {
    final ym = ymAddMonths(nowYm(), -i);
    final grow = (6 - i);
    await repo.saveSnapshot(
      ym: ym,
      amountsByAccountId: {
        accounts[0].id: (d.netWorth * 0.30).round() + d.saving * grow,
        accounts[1].id: (d.netWorth * 0.42).round() + d.saving * grow,
        accounts[2].id: (d.netWorth * 0.18).round(),
        accounts[3].id: (d.netWorth * 0.10).round(),
      },
      income: d.income,
      expense: d.expense,
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 하단 탭 이동 — 같은 아이콘이 본문에도 있어(예: '포트폴리오로 구성') 탭바로 범위를 좁힌다
  Future<void> tapTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.byIcon(icon)));
    await tester.pumpAndSettle();
  }

  /// 화면을 띄운 뒤 [_hold]만큼 머문다. 캡처는 바깥(`tool/screenshots.sh`)에서
  /// `xcrun simctl io screenshot`으로 한다 — iOS에서 integration_test의
  /// takeScreenshot이 드라이버 응답을 기다리며 멈추는 일이 있어 쓰지 않는다.
  Future<void> hold(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT_READY $name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
    await tester.pumpAndSettle();
  }

  testWidgets('스토어 스크린샷 ($_locale/$_currency)', (tester) async {
    await pumpApp(tester, seed: _seed, overrides: [
      // 몬테카를로는 isolate 대신 동기 실행 — 촬영 중 결과를 기다리지 않게
      monteCarloRunnerProvider.overrideWithValue(
          (request) async => runMonteCarlo(request)),
    ]);

    // 1) 홈 — 궤도 차트와 D-day
    await hold(tester, '01_home_orbit');

    // 2) 시뮬레이션 — What-if 슬라이더
    await tapTab(tester, Icons.query_stats);
    await hold(tester, '02_simulation');

    // 3) 자산 — 자산군 배분
    await tapTab(tester, Icons.pie_chart_outline);
    await hold(tester, '03_assets');

    // 4) 기록 — 월 스냅샷 입력
    await tapTab(tester, Icons.add_circle_outline);
    await hold(tester, '04_snapshot');
    if (find.byType(BackButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    // 5) 설정 — 프라이버시·언어·통화
    await tapTab(tester, Icons.home_outlined);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await hold(tester, '05_settings');
  });
}
