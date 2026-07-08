import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// 결정론 엔진 골든 테스트 (PRD §7 — 기준 케이스, 오차 <0.1%)
///
/// 기준값은 엔진과 독립적으로 구현한 참조 계산(폐형식 FV/NPER 수식과 교차검증)
/// 으로 생성했다. 엑셀 검증 방법:
/// - FIRE Number   = ROUND(은퇴후월지출 * 12 / SWR, 0)
/// - 월실질수익률 i = (1+연실질수익률)^(1/12) − 1
/// - 적립  매월     = ROUND(전월자산 * (1+i), 0) + 월저축
/// - 인출  매월     = ROUND(전월자산 * (1+i), 0) − 월인출
/// - 도달 월 수는 NPER(i, -월저축, -현재자산, FIRE Number)의 올림과 일치
///
/// 금액 기대값은 0.1% 상대 오차, 월 수·궤적 길이는 정확 일치를 요구한다.
void main() {
  group('적립(accumulation) 골든 케이스', () {
    for (final c in _accumulationCases) {
      test(c.name, () {
        final result = projectAccumulation(AccumulationInput(
          currentAssets: c.currentAssets,
          monthlySaving: c.monthlySaving,
          monthlyExpenseInRetirement: c.monthlyExpenseInRetirement,
          assumptions: SimulationAssumptions.real(
            realAnnualReturn: c.realAnnualReturn,
            safeWithdrawalRate: c.safeWithdrawalRate,
          ),
        ));

        expect(result.fireNumber, _within01Percent(c.expectedFireNumber));
        expect(result.monthsToFire, c.expectedMonthsToFire);
        expect(result.assetsByMonth.length, c.expectedTrajectoryLength);
        expect(
          result.assetsByMonth[c.checkpointMonth],
          _within01Percent(c.expectedAssetsAtCheckpoint),
        );
        expect(
          result.assetsByMonth.last,
          _within01Percent(c.expectedFinalAssets),
        );
      });
    }
  });

  group('인출(retirement) 골든 케이스', () {
    for (final c in _retirementCases) {
      test(c.name, () {
        final result = projectRetirement(RetirementInput(
          startAssets: c.startAssets,
          monthlyWithdrawal: c.monthlyWithdrawal,
          assumptions: SimulationAssumptions.real(
            realAnnualReturn: c.realAnnualReturn,
            safeWithdrawalRate: 0.04, // 인출 시뮬에는 미사용
          ),
          months: c.months,
        ));

        expect(result.depletionMonth, c.expectedDepletionMonth);
        expect(result.assetsByMonth.length, c.expectedTrajectoryLength);
        expect(
          result.assetsByMonth[60],
          _within01Percent(c.expectedAssetsAtMonth60),
        );
        expect(
          result.assetsByMonth.last,
          _within01Percent(c.expectedFinalAssets),
        );
      });
    }
  });

  group('가정(assumptions) 변환', () {
    test('실질수익률 = 명목 − 인플레이션', () {
      const a = SimulationAssumptions(
        nominalAnnualReturn: 0.06,
        annualInflation: 0.025,
        safeWithdrawalRate: 0.04,
      );
      expect(a.realAnnualReturn, closeTo(0.035, 1e-12));
    });

    test('월수익률은 기하 환산: (1+r)^(1/12) − 1', () {
      const a = SimulationAssumptions.real(
        realAnnualReturn: 0.035,
        safeWithdrawalRate: 0.04,
      );
      // (1.035)^(1/12) − 1 = 0.0028709...
      expect(a.monthlyRealReturn, closeTo(0.0028709, 1e-6));
    });
  });
}

Matcher _within01Percent(int expected) =>
    expected == 0 ? equals(0) : closeTo(expected, expected.abs() * 0.001);

class _AccumulationCase {
  final String name;
  final int currentAssets;
  final int monthlySaving;
  final int monthlyExpenseInRetirement;
  final double realAnnualReturn;
  final double safeWithdrawalRate;
  final int expectedFireNumber;
  final int? expectedMonthsToFire;
  final int checkpointMonth;
  final int expectedAssetsAtCheckpoint;
  final int expectedFinalAssets;
  final int expectedTrajectoryLength;

  const _AccumulationCase(
    this.name,
    this.currentAssets,
    this.monthlySaving,
    this.monthlyExpenseInRetirement,
    this.realAnnualReturn,
    this.safeWithdrawalRate, {
    required this.expectedFireNumber,
    required this.expectedMonthsToFire,
    this.checkpointMonth = 60,
    required this.expectedAssetsAtCheckpoint,
    required this.expectedFinalAssets,
    required this.expectedTrajectoryLength,
  });
}

const _accumulationCases = [
  _AccumulationCase(
    '기본: 1억 보유, 월 200만 저축, 실질 3.5%, 4% 룰',
    100000000, 2000000, 3000000, 0.035, 0.04,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: 243,
    expectedAssetsAtCheckpoint: 249519538,
    expectedFinalAssets: 902203013,
    expectedTrajectoryLength: 244,
  ),
  _AccumulationCase(
    '자산 0에서 시작',
    0, 1500000, 2500000, 0.04, 0.04,
    expectedFireNumber: 750000000,
    expectedMonthsToFire: 297,
    expectedAssetsAtCheckpoint: 99268537,
    expectedFinalAssets: 751354035,
    expectedTrajectoryLength: 298,
  ),
  _AccumulationCase(
    '고저축: 월 500만',
    50000000, 5000000, 3000000, 0.05, 0.04,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: 126,
    expectedAssetsAtCheckpoint: 402882766,
    expectedFinalAssets: 904639092,
    expectedTrajectoryLength: 127,
  ),
  _AccumulationCase(
    '보수적 수익률 2%, SWR 3.5%',
    300000000, 1000000, 2000000, 0.02, 0.035,
    expectedFireNumber: 685714286,
    expectedMonthsToFire: 216,
    expectedAssetsAtCheckpoint: 394243120,
    expectedFinalAssets: 687768558,
    expectedTrajectoryLength: 217,
  ),
  _AccumulationCase(
    '수익률 0% (저축만으로 도달)',
    100000000, 2000000, 2500000, 0.0, 0.04,
    expectedFireNumber: 750000000,
    expectedMonthsToFire: 325,
    expectedAssetsAtCheckpoint: 220000000,
    expectedFinalAssets: 750000000,
    expectedTrajectoryLength: 326,
  ),
  _AccumulationCase(
    '이미 FIRE 도달 (현재 자산 ≥ FIRE Number)',
    1000000000, 1000000, 3000000, 0.035, 0.04,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: 0,
    checkpointMonth: 0,
    expectedAssetsAtCheckpoint: 1000000000,
    expectedFinalAssets: 1000000000,
    expectedTrajectoryLength: 1,
  ),
  _AccumulationCase(
    '린 FIRE: 월 지출 150만',
    20000000, 800000, 1500000, 0.03, 0.04,
    expectedFireNumber: 450000000,
    expectedMonthsToFire: 329,
    expectedAssetsAtCheckpoint: 74850246,
    expectedFinalAssets: 450062863,
    expectedTrajectoryLength: 330,
  ),
  _AccumulationCase(
    '팻 FIRE: 월 지출 800만, SWR 3.5%',
    500000000, 4000000, 8000000, 0.045, 0.035,
    expectedFireNumber: 2742857143,
    expectedMonthsToFire: 241,
    expectedAssetsAtCheckpoint: 891057999,
    expectedFinalAssets: 2756574349,
    expectedTrajectoryLength: 242,
  ),
  _AccumulationCase(
    'SWR 3% (보수적 인출)',
    100000000, 2000000, 3000000, 0.035, 0.03,
    expectedFireNumber: 1200000000,
    expectedMonthsToFire: 303,
    expectedAssetsAtCheckpoint: 249519538,
    expectedFinalAssets: 1202285069,
    expectedTrajectoryLength: 304,
  ),
  _AccumulationCase(
    'SWR 5% (공격적 인출)',
    100000000, 2000000, 3000000, 0.035, 0.05,
    expectedFireNumber: 720000000,
    expectedMonthsToFire: 201,
    expectedAssetsAtCheckpoint: 249519538,
    expectedFinalAssets: 720831685,
    expectedTrajectoryLength: 202,
  ),
  _AccumulationCase(
    '공격적 수익률 7%',
    100000000, 2000000, 3000000, 0.07, 0.04,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: 181,
    expectedAssetsAtCheckpoint: 282646885,
    expectedFinalAssets: 905190723,
    expectedTrajectoryLength: 182,
  ),
  _AccumulationCase(
    '저축 없이 성장만으로 도달',
    400000000, 0, 2000000, 0.05, 0.04,
    expectedFireNumber: 600000000,
    expectedMonthsToFire: 100,
    expectedAssetsAtCheckpoint: 510512626,
    expectedFinalAssets: 600672134,
    expectedTrajectoryLength: 101,
  ),
  _AccumulationCase(
    '저축 음수 → 도달 불가 (자산 감소)',
    100000000, -500000, 3000000, 0.02, 0.04,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: null,
    expectedAssetsAtCheckpoint: 78898638,
    expectedFinalAssets: -1166040673,
    expectedTrajectoryLength: 1201,
  ),
  _AccumulationCase(
    '수익 0·저축 0 → 도달 불가 (자산 정체)',
    100000000, 0, 3000000, 0.0, 0.04,
    expectedFireNumber: 900000000,
    expectedMonthsToFire: null,
    expectedAssetsAtCheckpoint: 100000000,
    expectedFinalAssets: 100000000,
    expectedTrajectoryLength: 1201,
  ),
];

class _RetirementCase {
  final String name;
  final int startAssets;
  final int monthlyWithdrawal;
  final double realAnnualReturn;
  final int months;
  final int? expectedDepletionMonth;
  final int expectedAssetsAtMonth60;
  final int expectedFinalAssets;
  final int expectedTrajectoryLength;

  const _RetirementCase(
    this.name,
    this.startAssets,
    this.monthlyWithdrawal,
    this.realAnnualReturn,
    this.months, {
    required this.expectedDepletionMonth,
    required this.expectedAssetsAtMonth60,
    required this.expectedFinalAssets,
    required this.expectedTrajectoryLength,
  });
}

const _retirementCases = [
  _RetirementCase(
    '생존: 9억, 월 300만 인출, 실질 3.5%, 40년',
    900000000, 3000000, 0.035, 480,
    expectedDepletionMonth: null,
    expectedAssetsAtMonth60: 872791318,
    expectedFinalAssets: 470999267,
    expectedTrajectoryLength: 481,
  ),
  _RetirementCase(
    '고갈: 6억, 월 300만 인출, 실질 2%',
    600000000, 3000000, 0.02, 600,
    expectedDepletionMonth: 243,
    expectedAssetsAtMonth60: 473391846,
    expectedFinalAssets: 0,
    expectedTrajectoryLength: 244,
  ),
  _RetirementCase(
    '수익 0: 3.6억 ÷ 300만 = 정확히 120개월 후 고갈',
    360000000, 3000000, 0.0, 240,
    expectedDepletionMonth: 120,
    expectedAssetsAtMonth60: 180000000,
    expectedFinalAssets: 0,
    expectedTrajectoryLength: 121,
  ),
  _RetirementCase(
    '이자 > 인출: 12억, 월 300만, 실질 3.5% — 자산 증가',
    1200000000, 3000000, 0.035, 720,
    expectedDepletionMonth: null,
    expectedAssetsAtMonth60: 1229097207,
    expectedFinalAssets: 2266317754,
    expectedTrajectoryLength: 721,
  ),
  _RetirementCase(
    '늦은 고갈: 8억, 월 350만 인출, 실질 3%',
    800000000, 3500000, 0.03, 600,
    expectedDepletionMonth: 337,
    expectedAssetsAtMonth60: 701385895,
    expectedFinalAssets: 0,
    expectedTrajectoryLength: 338,
  ),
  _RetirementCase(
    '짧은 지평 생존: 5억, 월 300만, 10년',
    500000000, 3000000, 0.025, 120,
    expectedDepletionMonth: null,
    expectedAssetsAtMonth60: 374317712,
    expectedFinalAssets: 232119740,
    expectedTrajectoryLength: 121,
  ),
];
