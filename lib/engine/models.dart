import 'dart:math' as math;

/// 시뮬레이션 가정.
///
/// 모든 계산은 실질(인플레이션 조정) 기준이다:
/// 실질수익률 = 명목수익률 − 인플레이션 (PRD §7).
/// 은퇴 후 인출액은 실질 기준 고정이며, 이는 인플레이션 연동 명목 인출과 같다.
class SimulationAssumptions {
  /// 명목 기대수익률 (연, 예: 0.06 = 6%)
  final double nominalAnnualReturn;

  /// 기대 인플레이션 (연)
  final double annualInflation;

  /// 안전인출률 (예: 0.04 = 4% 룰)
  final double safeWithdrawalRate;

  const SimulationAssumptions({
    required this.nominalAnnualReturn,
    required this.annualInflation,
    required this.safeWithdrawalRate,
  });

  /// 실질수익률을 직접 지정하는 생성자.
  const SimulationAssumptions.real({
    required double realAnnualReturn,
    required this.safeWithdrawalRate,
  })  : nominalAnnualReturn = realAnnualReturn,
        annualInflation = 0;

  /// 실질수익률 (연) = 명목 − 인플레이션
  double get realAnnualReturn => nominalAnnualReturn - annualInflation;

  /// 월 실질수익률 — 연 수익률의 기하 환산: (1+r)^(1/12) − 1
  double get monthlyRealReturn =>
      math.pow(1 + realAnnualReturn, 1 / 12).toDouble() - 1.0;
}
