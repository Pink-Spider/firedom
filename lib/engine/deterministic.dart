import 'models.dart';

/// FIRE Number = 은퇴 후 연 지출 / 안전인출률 (원 단위 반올림)
int fireNumberOf({
  required int monthlyExpenseInRetirement,
  required double safeWithdrawalRate,
}) {
  return (monthlyExpenseInRetirement * 12 / safeWithdrawalRate).round();
}

/// 적립(은퇴 준비) 구간 시뮬레이션 입력. 금액은 모두 정수 원.
class AccumulationInput {
  /// 현재 순자산 (원)
  final int currentAssets;

  /// 월 저축액 (원) = 세후 월소득 − 월 지출. 음수 허용(자산 감소 시나리오).
  final int monthlySaving;

  /// 은퇴 후 월 생활비 (원, 실질)
  final int monthlyExpenseInRetirement;

  final SimulationAssumptions assumptions;

  /// 시뮬레이션 상한 (기본 100년). 이 안에 도달하지 못하면 도달 불가로 본다.
  final int maxMonths;

  const AccumulationInput({
    required this.currentAssets,
    required this.monthlySaving,
    required this.monthlyExpenseInRetirement,
    required this.assumptions,
    this.maxMonths = 1200,
  });
}

class AccumulationResult {
  /// 목표 자산 (FIRE Number, 원)
  final int fireNumber;

  /// FIRE Number 도달까지 월 수. 0 = 이미 도달, null = maxMonths 내 도달 불가.
  final int? monthsToFire;

  /// 월별 자산 궤적. [0] = 현재. 도달 시 도달 월까지, 미도달 시 maxMonths까지.
  final List<int> assetsByMonth;

  const AccumulationResult({
    required this.fireNumber,
    required this.monthsToFire,
    required this.assetsByMonth,
  });

  bool get isReachable => monthsToFire != null;
}

/// 결정론 적립 시뮬레이션 (PRD §7).
///
/// 매월: 자산(t+1) = round(자산(t) × (1+월실질수익률)) + 월저축
AccumulationResult projectAccumulation(AccumulationInput input) {
  final fireNumber = fireNumberOf(
    monthlyExpenseInRetirement: input.monthlyExpenseInRetirement,
    safeWithdrawalRate: input.assumptions.safeWithdrawalRate,
  );
  final monthlyRate = input.assumptions.monthlyRealReturn;

  var assets = input.currentAssets;
  final trajectory = <int>[assets];
  int? monthsToFire = assets >= fireNumber ? 0 : null;

  if (monthsToFire == null) {
    for (var month = 1; month <= input.maxMonths; month++) {
      assets = (assets * (1 + monthlyRate)).round() + input.monthlySaving;
      trajectory.add(assets);
      if (assets >= fireNumber) {
        monthsToFire = month;
        break;
      }
    }
  }

  return AccumulationResult(
    fireNumber: fireNumber,
    monthsToFire: monthsToFire,
    assetsByMonth: trajectory,
  );
}

/// 인출(은퇴 후) 구간 시뮬레이션 입력. 금액은 모두 정수 원.
class RetirementInput {
  /// 은퇴 시점 자산 (원)
  final int startAssets;

  /// 월 인출액 (원, 실질 — 인플레이션 연동 명목 인출과 동일)
  final int monthlyWithdrawal;

  final SimulationAssumptions assumptions;

  /// 기대수명까지 월 수
  final int months;

  const RetirementInput({
    required this.startAssets,
    required this.monthlyWithdrawal,
    required this.assumptions,
    required this.months,
  });
}

class RetirementResult {
  /// 월별 자산 궤적. [0] = 은퇴 시점. 고갈 시 0으로 끝난다.
  final List<int> assetsByMonth;

  /// 자산이 처음 0 이하가 되는 월 (은퇴 시점부터). null = 기간 내 고갈 없음.
  final int? depletionMonth;

  const RetirementResult({
    required this.assetsByMonth,
    required this.depletionMonth,
  });

  bool get survives => depletionMonth == null;
}

/// 결정론 인출 시뮬레이션 (PRD §7).
///
/// 매월: 자산(t+1) = round(자산(t) × (1+월실질수익률)) − 월인출
RetirementResult projectRetirement(RetirementInput input) {
  final monthlyRate = input.assumptions.monthlyRealReturn;

  var assets = input.startAssets;
  final trajectory = <int>[assets];
  int? depletionMonth;

  for (var month = 1; month <= input.months; month++) {
    assets = (assets * (1 + monthlyRate)).round() - input.monthlyWithdrawal;
    if (assets <= 0) {
      depletionMonth = month;
      trajectory.add(0);
      break;
    }
    trajectory.add(assets);
  }

  return RetirementResult(
    assetsByMonth: trajectory,
    depletionMonth: depletionMonth,
  );
}
