import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A7 궤도 편차', () {
    // 선형 곡선: plan[s] = 10,000 + 1,000s (검산 용이)
    final plan = [for (var s = 0; s <= 20; s++) 10000 + 1000 * s];
    const fireNumber = 40000;

    test('실제 자산이 계획 10개월 지점 값인데 8개월 경과 → +2개월 앞섬', () {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: plan,
        fireNumber: fireNumber,
        actualAssets: 20000, // = plan[10]
        monthsElapsed: 8,
      );
      expect(deviation, closeTo(2.0, 1e-9));
    });

    test('선형 보간: 두 월 사이 중간값 → 소수 월', () {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: plan,
        fireNumber: fireNumber,
        actualAssets: 15500, // plan[5]=15000, plan[6]=16000의 중간
        monthsElapsed: 5,
      );
      expect(deviation, closeTo(0.5, 1e-9));
    });

    test('뒤처짐은 음수', () {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: plan,
        fireNumber: fireNumber,
        actualAssets: 20000, // t_equiv = 10
        monthsElapsed: 13,
      );
      expect(deviation, closeTo(-3.0, 1e-9));
    });

    test('이미 목표 도달(actual ≥ FIRE_number) → null', () {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: plan,
        fireNumber: fireNumber,
        actualAssets: 40000,
        monthsElapsed: 10,
      );
      expect(deviation, isNull);
    });

    test('계획 시작점에도 못 미침 → t_equiv = 0', () {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: plan,
        fireNumber: fireNumber,
        actualAssets: 5000, // < plan[0]
        monthsElapsed: 4,
      );
      expect(deviation, closeTo(-4.0, 1e-9));
    });

    test('실제 엔진 곡선과 결합: G1 계획에서 정확히 궤도 위 → 편차 0', () {
      const g1 = PlanInput(
        age0: 35,
        currentAssets: 100000000,
        monthlySaving: 2000000,
        realReturnBp: 400,
        monthlySpendRetire: 3000000,
      );
      final result = solvePlan(g1);
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: result.assetsByMonth,
        fireNumber: result.fireNumber,
        actualAssets: result.assetsByMonth[24],
        monthsElapsed: 24,
      );
      expect(deviation, closeTo(0.0, 1e-6));
    });
  });

  group('A8 저축률', () {
    test('기본: (500만 − 300만) / 500만 = 40%', () {
      expect(savingRate(income: 5000000, expense: 3000000), closeTo(0.4, 1e-9));
    });

    test('소득 ≤ 0 → null (미정의)', () {
      expect(savingRate(income: 0, expense: 3000000), isNull);
      expect(savingRate(income: -1, expense: 0), isNull);
    });

    test('지출 > 소득 → 음수 허용', () {
      expect(savingRate(income: 3000000, expense: 3600000),
          closeTo(-0.2, 1e-9));
    });
  });
}
