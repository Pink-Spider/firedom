import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('몬테카를로 — 재현성', () {
    test('같은 시드는 같은 결과를 낸다', () {
      const input = MonteCarloInput(
        currentAssets: 100000000,
        monthlySaving: 2000000,
        accumulationMonths: 120,
        monthlyWithdrawal: 3000000,
        retirementMonths: 360,
        annualExpectedReturn: 0.035,
        annualVolatility: 0.15,
        runs: 500,
        seed: 42,
      );

      final a = runMonteCarlo(input);
      final b = runMonteCarlo(input);

      expect(a.successes, b.successes);
      expect(a.endingAssets, b.endingAssets);
      expect(a.depletionMonths, b.depletionMonths);
    });
  });

  group('몬테카를로 — 변동성 0이면 결정론 엔진과 일치', () {
    test('생존 케이스: 성공률 1.0, 최종 자산이 결정론 결과와 같다', () {
      // 결정론 골든 케이스와 동일 입력: 12억, 월 300만 인출, 실질 3.5%, 720개월
      const input = MonteCarloInput(
        currentAssets: 1200000000,
        monthlySaving: 0,
        accumulationMonths: 0,
        monthlyWithdrawal: 3000000,
        retirementMonths: 720,
        annualExpectedReturn: 0.035,
        annualVolatility: 0.0,
        runs: 50,
        seed: 1,
      );

      final result = runMonteCarlo(input);

      expect(result.successRate, 1.0);
      // 결정론 골든 기대값과 동일해야 한다
      expect(result.endingAssets.first, 2266317754);
      expect(result.endingAssets.last, 2266317754);
    });

    test('고갈 케이스: 성공률 0.0, 고갈 월이 결정론 결과와 같다', () {
      // 결정론 골든 케이스와 동일 입력: 6억, 월 300만 인출, 실질 2%, 600개월
      const input = MonteCarloInput(
        currentAssets: 600000000,
        monthlySaving: 0,
        accumulationMonths: 0,
        monthlyWithdrawal: 3000000,
        retirementMonths: 600,
        annualExpectedReturn: 0.02,
        annualVolatility: 0.0,
        runs: 50,
        seed: 1,
      );

      final result = runMonteCarlo(input);

      expect(result.successRate, 0.0);
      expect(result.depletionMonths, everyElement(243));
    });

    test('적립 구간: 최종 자산이 결정론 결과와 같다', () {
      // 결정론 골든 케이스와 동일 입력: 1억, 월 200만 저축, 실질 3.5%, 243개월
      const input = MonteCarloInput(
        currentAssets: 100000000,
        monthlySaving: 2000000,
        accumulationMonths: 243,
        monthlyWithdrawal: 0,
        retirementMonths: 0,
        annualExpectedReturn: 0.035,
        annualVolatility: 0.0,
        runs: 10,
        seed: 1,
      );

      final result = runMonteCarlo(input);

      expect(result.successRate, 1.0);
      expect(result.endingAssets.first, 902203013);
    });
  });

  group('몬테카를로 — 분포 특성', () {
    test('변동성이 있으면 성공/실패가 섞이고 백분위수는 단조 증가한다', () {
      const input = MonteCarloInput(
        currentAssets: 900000000,
        monthlySaving: 0,
        accumulationMonths: 0,
        monthlyWithdrawal: 3000000,
        retirementMonths: 480,
        annualExpectedReturn: 0.035,
        annualVolatility: 0.15,
        runs: 1000,
        seed: 7,
      );

      final result = runMonteCarlo(input);

      expect(result.successes, greaterThan(0));
      expect(result.successes, lessThan(input.runs));
      expect(result.endingAssets.length, input.runs);
      expect(
        result.successes + result.depletionMonths.length,
        input.runs,
      );

      final p10 = result.endingAssetsPercentile(0.1);
      final p50 = result.endingAssetsPercentile(0.5);
      final p90 = result.endingAssetsPercentile(0.9);
      expect(p10, lessThanOrEqualTo(p50));
      expect(p50, lessThanOrEqualTo(p90));
    });
  });
}
