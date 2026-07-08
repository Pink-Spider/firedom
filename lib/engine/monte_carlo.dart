import 'dart:math' as math;

/// 몬테카를로 시뮬레이션 입력. 금액은 모두 정수 원, 수익률은 실질 기준.
///
/// 월수익률을 정규분포 N(월기대수익률, 월변동성)에서 샘플링한다 (PRD §7).
/// - 월기대수익률 = (1+연기대수익률)^(1/12) − 1
/// - 월변동성 = 연변동성 / √12
class MonteCarloInput {
  /// 현재 순자산 (원)
  final int currentAssets;

  /// 적립 구간 월 저축액 (원)
  final int monthlySaving;

  /// 적립(은퇴까지) 월 수. 0이면 즉시 은퇴.
  final int accumulationMonths;

  /// 은퇴 후 월 인출액 (원, 실질)
  final int monthlyWithdrawal;

  /// 은퇴 후 기대수명까지 월 수
  final int retirementMonths;

  /// 연 기대수익률 (실질)
  final double annualExpectedReturn;

  /// 연 변동성 (표준편차, 예: 0.15)
  final double annualVolatility;

  /// 시뮬레이션 횟수 (기본 5,000회)
  final int runs;

  /// 시드. 지정하면 동일 입력 → 동일 결과 (재현성).
  final int? seed;

  const MonteCarloInput({
    required this.currentAssets,
    required this.monthlySaving,
    required this.accumulationMonths,
    required this.monthlyWithdrawal,
    required this.retirementMonths,
    required this.annualExpectedReturn,
    required this.annualVolatility,
    this.runs = 5000,
    this.seed,
  });
}

class MonteCarloResult {
  final int runs;

  /// 성공 횟수. 성공 = 기대수명까지 자산 > 0 유지.
  final int successes;

  /// 런별 기대수명 시점 자산 (원, 실질). 오름차순 정렬. 고갈 런은 0.
  final List<int> endingAssets;

  /// 실패 런의 고갈 월 (은퇴 시점부터). 오름차순 정렬.
  final List<int> depletionMonths;

  const MonteCarloResult({
    required this.runs,
    required this.successes,
    required this.endingAssets,
    required this.depletionMonths,
  });

  double get successRate => successes / runs;

  /// 기대수명 시점 자산의 백분위수 (p: 0.0~1.0)
  int endingAssetsPercentile(double p) {
    assert(p >= 0 && p <= 1);
    final index = ((endingAssets.length - 1) * p).round();
    return endingAssets[index];
  }
}

/// 몬테카를로 시뮬레이션 실행.
///
/// 순수 함수(톱레벨)이므로 `compute()`로 isolate에서 실행할 수 있다.
MonteCarloResult runMonteCarlo(MonteCarloInput input) {
  final rng =
      input.seed == null ? math.Random() : math.Random(input.seed);
  final gaussian = _Gaussian(rng);

  final monthlyMean =
      math.pow(1 + input.annualExpectedReturn, 1 / 12).toDouble() - 1.0;
  final monthlySigma = input.annualVolatility / math.sqrt(12);

  var successes = 0;
  final endingAssets = <int>[];
  final depletionMonths = <int>[];

  for (var run = 0; run < input.runs; run++) {
    var assets = input.currentAssets;

    for (var month = 0; month < input.accumulationMonths; month++) {
      final rate = monthlyMean + gaussian.next() * monthlySigma;
      assets = (assets * (1 + rate)).round() + input.monthlySaving;
    }

    var depleted = false;
    for (var month = 1; month <= input.retirementMonths; month++) {
      final rate = monthlyMean + gaussian.next() * monthlySigma;
      assets = (assets * (1 + rate)).round() - input.monthlyWithdrawal;
      if (assets <= 0) {
        depleted = true;
        depletionMonths.add(month);
        assets = 0;
        break;
      }
    }

    if (!depleted) successes++;
    endingAssets.add(assets);
  }

  endingAssets.sort();
  depletionMonths.sort();

  return MonteCarloResult(
    runs: input.runs,
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
