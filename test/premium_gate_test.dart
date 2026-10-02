import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/entitlements.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/engine/engine.dart';
import 'package:firedom/features/paywall/paywall_sheet.dart';
import 'package:firedom/features/simulation/monte_carlo_runner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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

/// url_launcher를 가로채 실제로 열린 URL을 기록한다.
class _RecordingLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
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

    // 혜택 목록에는 지금 제공되는 기능만 올린다.
    // 미출시 기능을 올리면 '결제했는데 안 열린다'는 오인 구매가 된다.
    expect(find.text('포트폴리오 비중 자유 편집'), findsOneWidget);
    expect(find.text('출시 예정'), findsNothing);
    // 스토어 가격을 못 받아온 상태의 안내 — 금액·통화를 박지 않고 체험 조건만 알린다
    expect(find.textContaining('7일 무료 체험'), findsOneWidget);
    expect(find.textContaining('39,000'), findsNothing);

    // App Store 심사 3.1.2(c): 구독 화면의 이용약관(EULA)·개인정보 링크는
    // 렌더링만으로는 부족하고 **실제로 열려야** 한다.
    final launcher = _RecordingLauncher();
    final previous = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previous);

    await tester.tap(find.byKey(const ValueKey('paywall-terms-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('paywall-privacy-link')));
    await tester.pumpAndSettle();
    expect(launcher.launched, [paywallTermsUrl, paywallPrivacyUrl]);
    expect(paywallTermsUrl, contains('apple.com/legal'));

    // 가격을 모르는 화면에는 결제 개시 버튼을 두지 않는다 (App Store 3.1.2)
    expect(find.text('구독 시작하기'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('paywall-reload-prices')));
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

  appTest('설정: 프리미엄이 켜지면 구독 상태 표시가 갱신된다', (tester) async {
    // QA 토글 위젯은 --dart-define=FIREDOM_QA=true 빌드에만 있으므로(스토어 스크린샷에
    // 찍히는 사고를 막으려 디버그 자동 노출을 뺐다) 상태를 직접 바꿔 검증한다.
    final db = await pumpApp(tester, seed: (db) async => seedPlan(db));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('이용 중 🎉'), findsNothing);

    await EntitlementService(SettingsStore(db)).setDebugPremium(true);
    await tester.pumpAndSettle();

    expect(find.textContaining('이용 중 🎉'), findsOneWidget);
  });
}
