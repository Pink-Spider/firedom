import 'dart:math' as math;

import 'models.dart';

/// 시뮬 상한: 1,200개월 = 100년. 미도달 시 unreachable (엔진명세 R7)
const int maxSimulationMonths = 1200;

/// 모드 1 FIRE Number = round(은퇴 후 월 생활비 × 12 / SWR) (엔진명세 A2)
int fireNumberOf({required int monthlySpendRetire, required int swrBp}) {
  return (monthlySpendRetire * 12 / bpToRate(swrBp)).round();
}

/// 축적 궤적 (엔진명세 A3): asset[t+1] = round(asset[t] × (1+r_m)) + 월저축
///
/// 반환 리스트 길이는 months+1, [0] = 현재 순자산.
List<int> accumulationTrajectory(PlanInput input, {required int months}) {
  final monthlyRate = input.monthlyRealReturn;
  var assets = input.currentAssets;
  final trajectory = <int>[assets];
  for (var t = 0; t < months; t++) {
    assets = (assets * (1 + monthlyRate)).round() + input.monthlySaving;
    trajectory.add(assets);
  }
  return trajectory;
}

/// 인출 시뮬 결과 (엔진명세 A4)
class DrawdownResult {
  /// 월별 잔액. [0] = 은퇴 시점(월 R). 실패 시 마지막 원소가 음수.
  final List<int> assetsByMonth;

  /// 잔액이 처음 음수가 되는 절대 월 t (t=0 기준). null = 기대수명까지 생존.
  final int? failureMonth;

  const DrawdownResult({
    required this.assetsByMonth,
    required this.failureMonth,
  });

  bool get survives => failureMonth == null;
}

/// 인출 시뮬 (엔진명세 A4). [retirementMonth]부터 기대수명까지.
///
/// asset[t+1] = round(asset[t] × (1+r_m)) + income[t] − 은퇴 후 생활비
/// income[t] = (t ≥ 연금 개시 월) ? 연금 월액 : 0
/// 실패 조건: asset[t+1] < 0
DrawdownResult drawdown(
  PlanInput input, {
  required int retirementMonth,
  required int assetsAtRetirement,
}) {
  final monthlyRate = input.monthlyRealReturn;
  final npsStartMonth = input.npsStartMonth;

  var assets = assetsAtRetirement;
  final trajectory = <int>[assets];
  int? failureMonth;

  for (var t = retirementMonth; t < input.lifeMonths; t++) {
    final income = (npsStartMonth != null && t >= npsStartMonth)
        ? input.nps!.monthlyAmount
        : 0;
    assets = (assets * (1 + monthlyRate)).round() +
        income -
        input.monthlySpendRetire;
    trajectory.add(assets);
    if (assets < 0) {
      failureMonth = t + 1;
      break;
    }
  }

  return DrawdownResult(
    assetsByMonth: trajectory,
    failureMonth: failureMonth,
  );
}

/// FIRE 풀이 결과 (엔진명세 A2)
class FireResult {
  /// 표시용 FIRE Number.
  /// 모드 1: 공식값(월 생활비×12/SWR). 모드 2: 도달 시 asset[tF], 미도달 시 모드 1 공식값.
  final int fireNumber;

  /// FIRE 시점 tF (월). 0 = 이미 달성, null = unreachable (R7·A9).
  final int? monthsToFire;

  /// 계획 궤도(축적 곡선). 도달 시 0..tF, 미도달 시 0..탐색 상한.
  final List<int> assetsByMonth;

  const FireResult({
    required this.fireNumber,
    required this.monthsToFire,
    required this.assetsByMonth,
  });

  bool get isReachable => monthsToFire != null;
}

/// 계획 풀이 (엔진명세 A2).
/// 연금 입력 시 모드 2(인출 판정 — 정본), 아니면 모드 1(SWR 공식).
FireResult solvePlan(PlanInput input) {
  return input.nps == null
      ? solveFireBySwr(input)
      : solveFireByFeasibility(input);
}

/// 모드 1 (A2): FIRE 시점 = min{ t : asset[t] ≥ FIRE_number }
FireResult solveFireBySwr(PlanInput input) {
  final fireNumber = fireNumberOf(
    monthlySpendRetire: input.monthlySpendRetire,
    swrBp: input.swrBp,
  );
  final monthlyRate = input.monthlyRealReturn;

  var assets = input.currentAssets;
  final trajectory = <int>[assets];
  int? monthsToFire = assets >= fireNumber ? 0 : null;

  if (monthsToFire == null) {
    for (var t = 1; t <= maxSimulationMonths; t++) {
      assets = (assets * (1 + monthlyRate)).round() + input.monthlySaving;
      trajectory.add(assets);
      if (assets >= fireNumber) {
        monthsToFire = t;
        break;
      }
    }
  }

  return FireResult(
    fireNumber: fireNumber,
    monthsToFire: monthsToFire,
    assetsByMonth: trajectory,
  );
}

/// 모드 2 (A2): feasible(R) = R개월 후 은퇴 가정 시 기대수명까지 인출 생존.
/// tF = min{ R : feasible(R) } — R에 대한 단조성 가정 하에 이분 탐색.
FireResult solveFireByFeasibility(PlanInput input) {
  final rMax = math.min(maxSimulationMonths, input.lifeMonths);
  final accumulation = accumulationTrajectory(input, months: rMax);

  bool feasible(int r) => drawdown(
        input,
        retirementMonth: r,
        assetsAtRetirement: accumulation[r],
      ).survives;

  final fallbackFireNumber = fireNumberOf(
    monthlySpendRetire: input.monthlySpendRetire,
    swrBp: input.swrBp,
  );

  if (!feasible(rMax)) {
    return FireResult(
      fireNumber: fallbackFireNumber,
      monthsToFire: null,
      assetsByMonth: accumulation,
    );
  }

  var lo = 0;
  var hi = rMax;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    if (feasible(mid)) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }

  return FireResult(
    fireNumber: accumulation[lo],
    monthsToFire: lo,
    assetsByMonth: accumulation.sublist(0, lo + 1),
  );
}
