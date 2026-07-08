import 'dart:math' as math;

import 'models.dart';

/// FNV-1a 32비트 해시 — 몬테카를로 시드 규약 (엔진명세 A6)
int fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final code in input.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// 몬테카를로 요청 (엔진명세 A6).
///
/// 톱레벨 [runMonteCarlo]에 단일 인자로 전달 — `compute()`로 isolate 실행 가능.
class MonteCarloRequest {
  final PlanInput plan;

  /// 은퇴 월 (결정론 풀이의 tF를 고정해서 전달)
  final int retirementMonth;

  /// 경로 수 (기본 5,000)
  final int runs;

  /// 시드. null이면 입력 직렬화의 FNV-1a 해시 — 동일 입력 → 동일 결과.
  /// "다시 계산"은 앱 레이어에서 seed+1.
  final int? seed;

  const MonteCarloRequest({
    required this.plan,
    required this.retirementMonth,
    this.runs = 5000,
    this.seed,
  });

  int get effectiveSeed => seed ?? fnv1a(_canonicalString);

  String get _canonicalString => [
        plan.age0,
        plan.currentAssets,
        plan.monthlySaving,
        plan.realReturnBp,
        plan.monthlySpendRetire,
        plan.swrBp,
        plan.lifeExpectancy,
        plan.nps?.monthlyAmount ?? '',
        plan.nps?.startAge ?? '',
        plan.volatilityBp,
        retirementMonth,
        runs,
      ].join('|');
}

class MonteCarloResult {
  final int runs;

  /// 성공 경로 수. 성공 = 기대수명까지 잔액 ≥ 0 유지 (A6).
  final int successes;

  /// 경로별 기대수명 시점 잔액 (원, 실질). 오름차순. 실패 경로는 0.
  final List<int> endingAssets;

  /// 실패 경로의 고갈 절대 월 t (t=0 기준). 오름차순.
  /// 고갈 나이 = age0 + t ~/ 12 (R2).
  final List<int> depletionMonths;

  const MonteCarloResult({
    required this.runs,
    required this.successes,
    required this.endingAssets,
    required this.depletionMonths,
  });

  double get successRate => successes / runs;

  /// 기대수명 시점 잔액의 백분위수 (p: 0.0~1.0) — p10/p50/p90 밴드용
  int endingAssetsPercentile(double p) {
    assert(p >= 0 && p <= 1);
    final index = ((endingAssets.length - 1) * p).round();
    return endingAssets[index];
  }
}

/// 몬테카를로 실행 (엔진명세 A6).
///
/// 월 수익률은 로그정규 샘플링:
/// σ_m = σ_annual/√12, μ_m = ln(1+r_real)/12 − σ_m²/2, r_t = exp(N(μ_m, σ_m)) − 1
MonteCarloResult runMonteCarlo(MonteCarloRequest request) {
  final plan = request.plan;
  final rng = math.Random(request.effectiveSeed);
  final gaussian = _Gaussian(rng);

  final sigmaM = bpToRate(plan.volatilityBp) / math.sqrt(12);
  final muM =
      math.log(1 + bpToRate(plan.realReturnBp)) / 12 - sigmaM * sigmaM / 2;

  final lifeMonths = plan.lifeMonths;
  final retirementMonth = math.min(request.retirementMonth, lifeMonths);
  final npsStartMonth = plan.npsStartMonth;

  var successes = 0;
  final endingAssets = <int>[];
  final depletionMonths = <int>[];

  for (var run = 0; run < request.runs; run++) {
    var assets = plan.currentAssets;
    var failedAt = -1;

    for (var t = 0; t < lifeMonths; t++) {
      final rate = math.exp(muM + gaussian.next() * sigmaM) - 1.0;
      final int cashflow;
      if (t < retirementMonth) {
        cashflow = plan.monthlySaving;
      } else {
        final income = (npsStartMonth != null && t >= npsStartMonth)
            ? plan.nps!.monthlyAmount
            : 0;
        cashflow = income - plan.monthlySpendRetire;
      }
      assets = (assets * (1 + rate)).round() + cashflow;
      if (assets < 0) {
        failedAt = t + 1;
        break;
      }
    }

    if (failedAt < 0) {
      successes++;
      endingAssets.add(assets);
    } else {
      depletionMonths.add(failedAt);
      endingAssets.add(0);
    }
  }

  endingAssets.sort();
  depletionMonths.sort();

  return MonteCarloResult(
    runs: request.runs,
    successes: successes,
    endingAssets: endingAssets,
    depletionMonths: depletionMonths,
  );
}

/// 표준정규분포 샘플러 (Marsaglia polar method)
class _Gaussian {
  final math.Random _rng;
  double? _spare;

  _Gaussian(this._rng);

  double next() {
    final spare = _spare;
    if (spare != null) {
      _spare = null;
      return spare;
    }
    double u, v, s;
    do {
      u = _rng.nextDouble() * 2 - 1;
      v = _rng.nextDouble() * 2 - 1;
      s = u * u + v * v;
    } while (s >= 1 || s == 0);
    final multiplier = math.sqrt(-2 * math.log(s) / s);
    _spare = v * multiplier;
    return u * multiplier;
  }
}
