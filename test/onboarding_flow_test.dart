import 'package:firedom/app/app.dart';
import 'package:firedom/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FiredomApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enterAnswer(WidgetTester tester, String text,
    {required String nextLabel}) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text(nextLabel));
  await tester.pumpAndSettle();
}

/// G1 골든과 동일 입력: 35세, 소득 500만, 지출 300만, 자산 1억
/// → 저축 200만/월, 실질 400bp(중립), tF=231 → FIRE 나이 54세
Future<void> completeOnboarding(WidgetTester tester) async {
  await enterAnswer(tester, '35', nextLabel: '다음'); // 나이
  await enterAnswer(tester, '500', nextLabel: '다음'); // 소득 (만원)
  await enterAnswer(tester, '300', nextLabel: '다음'); // 지출 (만원)
  await enterAnswer(tester, '10000', nextLabel: '결과 보기'); // 자산 1억 (만원)
}

void main() {
  testWidgets('S1: 4문항 완료 → S2에서 FIRE 나이 54세 (G1 입력)', (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('나이'), findsWidgets); // 1문항
    await completeOnboarding(tester);

    expect(find.text('당신의 FIRE 나이'), findsOneWidget);
    // 헤드라인 + 차트 축 눈금에 함께 나타날 수 있다
    expect(find.text('54세'), findsWidgets);
    expect(find.textContaining('9억'), findsWidgets); // FIRE Number
  });

  testWidgets('S1: 만원 단위 입력 도우미 텍스트 표시', (tester) async {
    await pumpApp(tester);
    await enterAnswer(tester, '35', nextLabel: '다음');

    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    expect(find.text('= 500만원'), findsOneWidget);
  });

  testWidgets('S2: What-if 슬라이더 최대(+300만) → 45세로 단축', (tester) async {
    await pumpApp(tester);
    await completeOnboarding(tester);

    // 저축 500만/월 → tF=123 → 35 + 10 = 45세
    await tester.ensureVisible(find.byType(Slider));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(find.text('45세'), findsWidgets);
    expect(find.textContaining('+300만원 →'), findsOneWidget);
  });

  testWidgets('S2: 지출 ≥ 소득이면 계산 불가 안내 (크래시 금지)', (tester) async {
    await pumpApp(tester);
    await enterAnswer(tester, '35', nextLabel: '다음');
    await enterAnswer(tester, '300', nextLabel: '다음'); // 소득 300만
    await enterAnswer(tester, '300', nextLabel: '다음'); // 지출 300만
    await enterAnswer(tester, '10000', nextLabel: '결과 보기');

    expect(find.textContaining('계산할 수 없어요'), findsOneWidget);
    expect(find.text('지출 조정하기'), findsOneWidget);

    // 지출 문항으로 복귀
    await tester.tap(find.text('지출 조정하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('얼마나 쓰세요'), findsOneWidget);
  });

  testWidgets('S1: 재실행 시 입력 중이던 단계에서 재개 (PRD 수용 기준)', (tester) async {
    await pumpApp(tester, prefsValues: {
      'onboarding.age': 35,
      'onboarding.monthly_income': 5000000,
      'onboarding.step': 2,
    });

    // 3번째 문항(지출)에서 재개
    expect(find.textContaining('얼마나 쓰세요'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
  });

  testWidgets('S2: 가정 보기 → 가정과 면책 문구 노출', (tester) async {
    await pumpApp(tester);
    await completeOnboarding(tester);

    await tester.scrollUntilVisible(find.text('가정 보기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('가정 보기'));
    await tester.pumpAndSettle();

    expect(find.text('계산에 사용한 가정'), findsOneWidget);
    expect(find.textContaining('투자 자문이 아닙니다'), findsOneWidget);
  });

  testWidgets('S2 CTA: 계획 저장 → 홈 진입, 재실행 시 홈부터 시작', (tester) async {
    await pumpApp(tester);
    await completeOnboarding(tester);

    await tester.scrollUntilVisible(find.text('이 계획 시작하기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 계획 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('나의 FIRE 계획'), findsOneWidget);
    expect(find.textContaining('54세'), findsOneWidget);

    // 저장 확인: 같은 prefs로 재기동하면 홈부터
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('active_plan_v0'), isTrue);
    expect(prefs.getInt('onboarding.step'), isNull); // 초안은 정리됨
  });
}
