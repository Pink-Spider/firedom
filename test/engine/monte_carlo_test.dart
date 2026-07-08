import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('G7: 몬테카를로 통계 검증 (엔진명세 A10)', () {
    // G1 입력 + 변동성 1200bp, 5,000경로, 은퇴 tF=231 고정, 수명 90
    const request = MonteCarloRequest(
      plan: PlanInput(
        age0: 35,
        currentAssets: 100000000,
        monthlySaving: 2000000,
        realReturnBp: 400,
        monthlySpendRetire: 3000000,
        swrBp: 400,
        lifeExpectancy: 90,
        volatilityBp: 1200,
      ),
      retirementMonth: 231,
      runs: 5000,
    );

    test('성공 확률 ∈ (0.5, 1.0)', () {
      final result = runMonteCarlo(request);
      expect(result.successRate, greaterThan(0.5));
      expect(result.successRate, lessThan(1.0));
    });

    test('동일 시드(입력 해시) 2회 실행 결과 완전 일치', () {
      final a = runMonteCarlo(request);
      final b = runMonteCarlo(request);
      expect(a.successes, b.successes);
      expect(a.endingAssets, b.endingAssets);
      expect(a.depletionMonths, b.depletionMonths);
    });

    test('p10 ≤ p50 ≤ p90', () {
      final r = runMonteCarlo(request);
      final p10 = r.endingAssetsPercentile(0.1);
      final p50 = r.endingAssetsPercentile(0.5);
      final p90 = r.endingAssetsPercentile(0.9);
      expect(p10, lessThanOrEqualTo(p50));
      expect(p50, lessThanOrEqualTo(p90));
    });

    test('성공 + 고갈 = 전체 경로, 고갈 월은 은퇴 이후', () {
      final r = runMonteCarlo(request);
      expect(r.successes + r.depletionMonths.length, request.runs);
      expect(r.endingAssets.length, request.runs);
      for (final month in r.depletionMonths.take(5)) {
        expect(month, greaterThan(request.retirementMonth));
      }
    });
  });

  group('시드 규약 (A6)', () {
    test('seed 미지정 시 입력 직렬화 FNV-1a 해시 사용', () {
      const a = MonteCarloRequest(
        plan: PlanInput(
          age0: 60, currentAssets: 500000000, monthlySaving: 0,
          realReturnBp: 400, monthlySpendRetire: 2000000,
        ),
        retirementMonth: 0,
        runs: 200,
      );
      expect(a.effectiveSeed, a.effectiveSeed); // 결정적
      // 입력이 다르면 시드도 다르다
      const b = MonteCarloRequest(
        plan: PlanInput(
          age0: 60, currentAssets: 500000001, monthlySaving: 0,
          realReturnBp: 400, monthlySpendRetire: 2000000,
        ),
        retirementMonth: 0,
        runs: 200,
      );
      expect(a.effectiveSeed, isNot(b.effectiveSeed));
    });

    test('seed+1 ("다시 계산")은 다른 경로를 만든다', () {
      const plan = PlanInput(
        age0: 60, currentAssets: 500000000, monthlySaving: 0,
        realReturnBp: 400, monthlySpendRetire: 2500000, volatilityBp: 1500,
      );
      const a = MonteCarloRequest(
          plan: plan, retirementMonth: 0, runs: 200, seed: 1000);
      const b = MonteCarloRequest(
          plan: plan, retirementMonth: 0, runs: 200, seed: 1001);
      expect(runMonteCarlo(a).endingAssets,
          isNot(runMonteCarlo(b).endingAssets));
    });

    test('FNV-1a 알려진 벡터', () {
      expect(fnv1a(''), 0x811c9dc5);
      expect(fnv1a('a'), 0xe40c292c);
    });
  });

  group('변동성 0 ↔ 결정론 엔진 교차 검증', () {
    test('인출 생존: 결정론 최종 잔액과 일치', () {
      // 인출 골든 케이스와 동일: 12억, 월 300만, 실질 3.5%, 720개월
      const request = MonteCarloRequest(
        plan: PlanInput(
          age0: 30, currentAssets: 1200000000, monthlySaving: 0,
          realReturnBp: 350, monthlySpendRetire: 3000000,
          lifeExpectancy: 90, volatilityBp: 0,
        ),
        retirementMonth: 0,
        runs: 20,
        seed: 1,
      );
      final r = runMonteCarlo(request);
      expect(r.successRate, 1.0);
      // pow와 exp/log 경로의 부동소수점 차이를 허용 (±100원)
      expect(r.endingAssets.first, closeTo(2266317754, 100));
      expect(r.endingAssets.last, closeTo(2266317754, 100));
    });

    test('인출 고갈: 결정론 고갈 월과 일치', () {
      // 인출 골든 케이스와 동일: 6억, 월 300만, 실질 2% → 243개월째 실패
      const request = MonteCarloRequest(
        plan: PlanInput(
          age0: 40, currentAssets: 600000000, monthlySaving: 0,
          realReturnBp: 200, monthlySpendRetire: 3000000,
          lifeExpectancy: 90, volatilityBp: 0,
        ),
        retirementMonth: 0,
        runs: 20,
        seed: 1,
      );
      final r = runMonteCarlo(request);
      expect(r.successRate, 0.0);
      expect(r.depletionMonths, everyElement(243));
    });

    test('축적 구간: 결정론 궤적과 일치', () {
      const plan = PlanInput(
        age0: 35, currentAssets: 100000000, monthlySaving: 2000000,
        realReturnBp: 400, monthlySpendRetire: 3000000,
        lifeExpectancy: 55, volatilityBp: 0,
      );
      const request = MonteCarloRequest(
        plan: plan,
        retirementMonth: 240, // lifeMonths와 동일 — 인출 구간 없음
        runs: 10,
        seed: 1,
      );
      final deterministic =
          accumulationTrajectory(plan, months: 240).last;
      final r = runMonteCarlo(request);
      expect(r.successRate, 1.0);
      expect(r.endingAssets.first, closeTo(deterministic, 100));
    });
  });
}
