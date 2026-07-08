import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// 결정론 엔진 골든 테스트
///
/// 1) `docs/엔진명세_스키마설계.md` A10의 G1~G6 — 명세 기대값과 **정확 일치**
/// 2) 추가 축적/인출 케이스 — 독립 참조 구현(Python, 폐형식 FV/NPER 교차검증)
///    으로 생성한 기준값. 금액은 오차 <0.1%(PRD §7), 월 수·길이는 정확 일치
///
/// 엑셀 검증 방법:
/// - FIRE Number   = ROUND(은퇴후월지출 * 12 / SWR, 0)
/// - 월실질수익률 i = (1+연실질수익률)^(1/12) − 1   (R4 기하 변환)
/// - 축적  매월     = ROUND(전월자산 * (1+i), 0) + 월저축   (R5)
/// - 인출  매월     = ROUND(전월자산 * (1+i), 0) + 연금 − 생활비, 실패: 잔액 < 0 (A4)
void main() {
  group('엔진명세 A10 골든 (정확 일치)', () {
    const g1 = PlanInput(
      age0: 35,
      currentAssets: 100000000,
      monthlySaving: 2000000,
      realReturnBp: 400,
      monthlySpendRetire: 3000000,
      swrBp: 400,
    );

    test('G1: 기본 케이스 — tF=231, asset[231]=901,642,042', () {
      final r = solvePlan(g1);
      expect(r.fireNumber, 900000000);
      expect(r.monthsToFire, 231);
      expect(r.assetsByMonth.length, 232);
      expect(r.assetsByMonth.last, 901642042);
    });

    test('G2: 저축 250만 — tF=201 (30개월 단축), asset[201]=902,242,019', () {
      final r = solvePlan(g1.copyWith(monthlySaving: 2500000));
      expect(r.monthsToFire, 201);
      expect(r.assetsByMonth.last, 902242019);
    });

    test('G3: 국민연금 100만/65세 → 모드 2, tF=64 (45세 4개월)', () {
      const g3 = PlanInput(
        age0: 40,
        currentAssets: 300000000,
        monthlySaving: 2500000,
        realReturnBp: 400,
        monthlySpendRetire: 2500000,
        nps: NpsInput(monthlyAmount: 1000000, startAge: 65),
        lifeExpectancy: 90,
      );
      final r = solvePlan(g3);
      expect(r.monthsToFire, 64);
      expect(r.assetsByMonth.length, 65);
      // 모드 2의 표시용 FIRE Number = 도달 시점 잔액
      expect(r.fireNumber, r.assetsByMonth.last);
    });

    test('G3b: G3에서 연금 제거 (판정 모드 유지) — tF=82', () {
      const g3b = PlanInput(
        age0: 40,
        currentAssets: 300000000,
        monthlySaving: 2500000,
        realReturnBp: 400,
        monthlySpendRetire: 2500000,
        lifeExpectancy: 90,
      );
      final r = solveFireByFeasibility(g3b);
      expect(r.monthsToFire, 82);
      // 연금 반영(G3)이 은퇴를 18개월 앞당긴다
      expect(82 - 64, 18);
    });

    test('G4: 자산 10억 — 이미 달성, tF=0', () {
      final r = solvePlan(g1.copyWith(currentAssets: 1000000000));
      expect(r.monthsToFire, 0);
      expect(r.assetsByMonth, [1000000000]);
    });

    test('G5: 자산 5억·저축 0 — tF=180, asset[180]=900,471,756', () {
      final r = solvePlan(g1.copyWith(
        currentAssets: 500000000,
        monthlySaving: 0,
      ));
      expect(r.fireNumber, 900000000);
      expect(r.monthsToFire, 180);
      expect(r.assetsByMonth.last, 900471756);
    });

    test('G6: 실질 0bp — tF=400, asset[400]=정확히 900,000,000', () {
      final r = solvePlan(g1.copyWith(realReturnBp: 0));
      expect(r.monthsToFire, 400);
      expect(r.assetsByMonth.last, 900000000);
    });

    test('solvePlan 디스패치: 연금 없으면 모드 1, 있으면 모드 2', () {
      // 모드 1과 모드 2는 같은 입력에서 다른 tF를 낸다 (G3b: 모드1이면 108)
      const input = PlanInput(
        age0: 40,
        currentAssets: 300000000,
        monthlySaving: 2500000,
        realReturnBp: 400,
        monthlySpendRetire: 2500000,
        lifeExpectancy: 90,
      );
      expect(solvePlan(input).monthsToFire,
          solveFireBySwr(input).monthsToFire);
      expect(solveFireBySwr(input).monthsToFire,
          isNot(solveFireByFeasibility(input).monthsToFire));
    });
  });

  group('추가 축적 골든 (금액 오차 <0.1%)', () {
    for (final c in _accumulationCases) {
      test(c.name, () {
        final r = solveFireBySwr(PlanInput(
          age0: 30,
          currentAssets: c.currentAssets,
          monthlySaving: c.monthlySaving,
          realReturnBp: c.realReturnBp,
          monthlySpendRetire: c.monthlySpendRetire,
          swrBp: c.swrBp,
          lifeExpectancy: 130, // 축적 골든은 R7 상한(1200개월)까지 관찰
        ));

        expect(r.fireNumber, _within01Percent(c.expectedFireNumber));
        expect(r.monthsToFire, c.expectedMonthsToFire);
        expect(r.assetsByMonth.length, c.expectedTrajectoryLength);
        expect(
          r.assetsByMonth[60],
          _within01Percent(c.expectedAssetsAtMonth60),
        );
        expect(r.assetsByMonth.last, _within01Percent(c.expectedFinalAssets));
      });
    }
  });

  group('인출(drawdown) 골든 (정확 일치)', () {
    for (final c in _drawdownCases) {
      test(c.name, () {
        final r = drawdown(
          c.plan,
          retirementMonth: 0,
          assetsAtRetirement: c.startAssets,
        );

        expect(r.failureMonth, c.expectedFailureMonth);
        expect(r.assetsByMonth.length, c.expectedTrajectoryLength);
        expect(r.assetsByMonth[60], c.expectedAssetsAtMonth60);
        expect(r.assetsByMonth.last, c.expectedFinalAssets);
      });
    }

    test('연금 개시 시점 잔액 확인 (브릿지 구간 통과)', () {
      // 45세 은퇴, 65세 연금 100만, 수명 90: 6억, 지출 250만, 실질 3%
      const plan = PlanInput(
        age0: 45,
        currentAssets: 0,
        monthlySaving: 0,
        realReturnBp: 300,
        monthlySpendRetire: 2500000,
        nps: NpsInput(monthlyAmount: 1000000, startAge: 65),
        lifeExpectancy: 90,
      );
      final r = drawdown(plan, retirementMonth: 0, assetsAtRetirement: 600000000);
      expect(r.assetsByMonth[240], 266530630); // 연금 개시 월
      expect(r.failureMonth, 475);
      expect(r.assetsByMonth.last, -1343957);
    });
  });

  group('변환·검증 (R4·R6·A9)', () {
    test('피셔 방정식: 명목 6%·인플레 2.5% → 실질 341bp (근사식 350 아님)', () {
      expect(fisherRealBp(nominalBp: 600, inflationBp: 250), 341);
      expect(fisherRealBp(nominalBp: 400, inflationBp: 0), 400);
    });

    test('bp → 비율', () {
      expect(bpToRate(400), 0.04);
      expect(bpToRate(0), 0.0);
    });

    test('월수익률은 기하 변환: (1.035)^(1/12) − 1', () {
      const input = PlanInput(
        age0: 30,
        currentAssets: 0,
        monthlySaving: 0,
        realReturnBp: 350,
        monthlySpendRetire: 1000000,
      );
      expect(input.monthlyRealReturn, closeTo(0.0028709, 1e-6));
    });

    test('기대수명 ≤ 현재 나이는 거부 (A9)', () {
      expect(
        () => PlanInput(
          age0: 90,
          currentAssets: 0,
          monthlySaving: 0,
          realReturnBp: 400,
          monthlySpendRetire: 1000000,
          lifeExpectancy: 90,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

Matcher _within01Percent(int expected) =>
    expected == 0 ? equals(0) : closeTo(expected, expected.abs() * 0.001);

class _AccumulationCase {
  final String name;
  final int currentAssets;
  final int monthlySaving;
  final int monthlySpendRetire;
  final int realReturnBp;
  final int swrBp;
  final int expectedFireNumber;
  final int? expectedMonthsToFire;
  final int expectedAssetsAtMonth60;
  final int expectedFinalAssets;
  final int expectedTrajectoryLength;

  const _AccumulationCase(
    this.name,
    this.currentAssets,
    this.monthlySaving,
    this.monthlySpendRetire,
    this.realReturnBp,
    this.swrBp, {
    required this.expectedFireNumber,
    required this.expectedMonthsToFire,
    required this.expectedAssetsAtMonth60,
    required this.expectedFinalAssets,
    required this.expectedTrajectoryLength,
  });
}

const _accumulationCases = [
  _AccumulationCase(
    '자산 0에서 시작 (실질 4%)',
    0, 1500000, 2500000, 400, 400,
    expectedFireNumber: 750000000,
    expectedMonthsToFire: 297,
    expectedAssetsAtMonth60: 99268537,
    expectedFinalAssets: 751354035,
    expectedTrajectoryLength: 298,
  ),
  _AccumulationCase(
    '고저축: 월 500만 (실질 5%)',
    50000000, 5000000, 3000000, 500, 400,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: 126,
    expectedAssetsAtMonth60: 402882766,
    expectedFinalAssets: 904639092,
    expectedTrajectoryLength: 127,
  ),
  _AccumulationCase(
    '보수적 수익률 2%, SWR 3.5%',
    300000000, 1000000, 2000000, 200, 350,
    expectedFireNumber: 685714286,
    expectedMonthsToFire: 216,
    expectedAssetsAtMonth60: 394243120,
    expectedFinalAssets: 687768558,
    expectedTrajectoryLength: 217,
  ),
  _AccumulationCase(
    '린 FIRE: 월 지출 150만 (실질 3%)',
    20000000, 800000, 1500000, 300, 400,
    expectedFireNumber: 450000000,
    expectedMonthsToFire: 329,
    expectedAssetsAtMonth60: 74850246,
    expectedFinalAssets: 450062863,
    expectedTrajectoryLength: 330,
  ),
  _AccumulationCase(
    '팻 FIRE: 월 지출 800만, SWR 3.5% (실질 4.5%)',
    500000000, 4000000, 8000000, 450, 350,
    expectedFireNumber: 2742857143,
    expectedMonthsToFire: 241,
    expectedAssetsAtMonth60: 891057999,
    expectedFinalAssets: 2756574349,
    expectedTrajectoryLength: 242,
  ),
  _AccumulationCase(
    'SWR 3% (보수적 인출, 실질 3.5%)',
    100000000, 2000000, 3000000, 350, 300,
    expectedFireNumber: 1200000000,
    expectedMonthsToFire: 303,
    expectedAssetsAtMonth60: 249519538,
    expectedFinalAssets: 1202285069,
    expectedTrajectoryLength: 304,
  ),
  _AccumulationCase(
    'SWR 5% (공격적 인출, 실질 3.5%)',
    100000000, 2000000, 3000000, 350, 500,
    expectedFireNumber: 720000000,
    expectedMonthsToFire: 201,
    expectedAssetsAtMonth60: 249519538,
    expectedFinalAssets: 720831685,
    expectedTrajectoryLength: 202,
  ),
  _AccumulationCase(
    '공격적 수익률 7%',
    100000000, 2000000, 3000000, 700, 400,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: 181,
    expectedAssetsAtMonth60: 282646885,
    expectedFinalAssets: 905190723,
    expectedTrajectoryLength: 182,
  ),
  _AccumulationCase(
    '저축 없이 성장만으로 도달 (실질 5%)',
    400000000, 0, 2000000, 500, 400,
    expectedFireNumber: 600000000,
    expectedMonthsToFire: 100,
    expectedAssetsAtMonth60: 510512626,
    expectedFinalAssets: 600672134,
    expectedTrajectoryLength: 101,
  ),
  _AccumulationCase(
    '저축 음수 → unreachable (자산 감소, R7)',
    100000000, -500000, 3000000, 200, 400,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: null,
    expectedAssetsAtMonth60: 78898638,
    expectedFinalAssets: -1166040673,
    expectedTrajectoryLength: 1201,
  ),
  _AccumulationCase(
    '수익 0·저축 0 → unreachable (자산 정체)',
    100000000, 0, 3000000, 0, 400,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: null,
    expectedAssetsAtMonth60: 100000000,
    expectedFinalAssets: 100000000,
    expectedTrajectoryLength: 1201,
  ),
];

class _DrawdownCase {
  final String name;
  final PlanInput plan;
  final int startAssets;
  final int? expectedFailureMonth;
  final int expectedAssetsAtMonth60;
  final int expectedFinalAssets;
  final int expectedTrajectoryLength;

  const _DrawdownCase(
    this.name,
    this.plan,
    this.startAssets, {
    required this.expectedFailureMonth,
    required this.expectedAssetsAtMonth60,
    required this.expectedFinalAssets,
    required this.expectedTrajectoryLength,
  });
}

const _drawdownCases = [
  _DrawdownCase(
    '생존: 9억, 월 300만, 실질 3.5%, 40년',
    PlanInput(
      age0: 50, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 350, monthlySpendRetire: 3000000, lifeExpectancy: 90,
    ),
    900000000,
    expectedFailureMonth: null,
    expectedAssetsAtMonth60: 872791318,
    expectedFinalAssets: 470999267,
    expectedTrajectoryLength: 481,
  ),
  _DrawdownCase(
    '고갈: 6억, 월 300만, 실질 2%, 50년 — 243개월째 실패',
    PlanInput(
      age0: 40, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 200, monthlySpendRetire: 3000000, lifeExpectancy: 90,
    ),
    600000000,
    expectedFailureMonth: 243,
    expectedAssetsAtMonth60: 473391846,
    expectedFinalAssets: -97169,
    expectedTrajectoryLength: 244,
  ),
  _DrawdownCase(
    '수익 0: 3.6억 ÷ 300만 — 120개월에 잔액 0(생존), 121개월째 실패',
    PlanInput(
      age0: 70, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 0, monthlySpendRetire: 3000000, lifeExpectancy: 90,
    ),
    360000000,
    expectedFailureMonth: 121,
    expectedAssetsAtMonth60: 180000000,
    expectedFinalAssets: -3000000,
    expectedTrajectoryLength: 122,
  ),
  _DrawdownCase(
    '이자 > 인출: 12억, 월 300만, 실질 3.5% — 자산 증가',
    PlanInput(
      age0: 30, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 350, monthlySpendRetire: 3000000, lifeExpectancy: 90,
    ),
    1200000000,
    expectedFailureMonth: null,
    expectedAssetsAtMonth60: 1229097207,
    expectedFinalAssets: 2266317754,
    expectedTrajectoryLength: 721,
  ),
  _DrawdownCase(
    '늦은 고갈: 8억, 월 350만, 실질 3% — 337개월째 실패',
    PlanInput(
      age0: 40, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 300, monthlySpendRetire: 3500000, lifeExpectancy: 90,
    ),
    800000000,
    expectedFailureMonth: 337,
    expectedAssetsAtMonth60: 701385895,
    expectedFinalAssets: -910527,
    expectedTrajectoryLength: 338,
  ),
  _DrawdownCase(
    '짧은 지평 생존: 5억, 월 300만, 10년',
    PlanInput(
      age0: 80, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 250, monthlySpendRetire: 3000000, lifeExpectancy: 90,
    ),
    500000000,
    expectedFailureMonth: null,
    expectedAssetsAtMonth60: 374317712,
    expectedFinalAssets: 232119740,
    expectedTrajectoryLength: 121,
  ),
  _DrawdownCase(
    '브릿지 구간 내 고갈: 4억, 지출 250만, 연금 100만/65세 (45세 은퇴)',
    PlanInput(
      age0: 45, currentAssets: 0, monthlySaving: 0,
      realReturnBp: 300, monthlySpendRetire: 2500000,
      nps: NpsInput(monthlyAmount: 1000000, startAge: 65),
      lifeExpectancy: 90,
    ),
    400000000,
    expectedFailureMonth: 204,
    expectedAssetsAtMonth60: 302257221,
    expectedFinalAssets: -637333,
    expectedTrajectoryLength: 205,
  ),
];
