/// A7 궤도 편차 + A8 저축률 (엔진명세) — 순수 함수
library;

/// 궤도 편차 (A7): 홈 S3 배지 "계획보다 N개월 앞".
///
/// t_equiv = min{ s : plan[s] ≥ actual } (인접 월 선형 보간으로 소수 월 허용)
/// 편차 = t_equiv − monthsElapsed (양수 = 계획보다 앞섬)
///
/// 반환 null = 이미 목표 도달 (actual ≥ fireNumber).
/// 스냅샷 < 2개 미표시는 UI 책임 (PRD S3).
double? trajectoryDeviationMonths({
  required List<int> planAssetsByMonth,
  required int fireNumber,
  required int actualAssets,
  required int monthsElapsed,
}) {
  assert(planAssetsByMonth.isNotEmpty);
  if (actualAssets >= fireNumber) return null;

  final plan = planAssetsByMonth;
  if (plan[0] >= actualAssets) {
    // 계획 시작점에도 못 미침 — t_equiv = 0
    return 0.0 - monthsElapsed;
  }
  for (var s = 1; s < plan.length; s++) {
    if (plan[s] >= actualAssets) {
      final previous = plan[s - 1];
      final step = plan[s] - previous;
      final fraction = step <= 0 ? 1.0 : (actualAssets - previous) / step;
      return (s - 1) + fraction - monthsElapsed;
    }
  }
  // 곡선이 actual까지 도달하지 못하는 경우 (미도달 계획) — 곡선 끝으로 클램프
  return (plan.length - 1).toDouble() - monthsElapsed;
}

/// 저축률 (A8): (소득 − 지출) / 소득.
///
/// income ≤ 0이면 미정의(null) → UI는 "—" 표시.
/// 음수 허용(지출 > 소득), 표시 하한 −100%는 UI 책임.
double? savingRate({required int income, required int expense}) {
  if (income <= 0) return null;
  return (income - expense) / income;
}
