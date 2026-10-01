/// 마일스톤 판정 (엔진명세 B1) — 스냅샷 저장 시 호출되는 순수 함수.
/// 판정은 엔진이 수행하고, 결과("달성 순간")만 DB에 기록한다.
library;

/// 순자산 구간 키 (5단계, 오름차순). 키 이름은 원화 기준으로 지어졌지만
/// 통화와 무관한 식별자로 쓴다 — 기준 금액은 호출자가 통화별로 넘긴다
const netWorthMilestoneKeys = [
  'net_worth_50m',
  'net_worth_100m',
  'net_worth_300m',
  'net_worth_500m',
  'net_worth_1b',
];

/// 원화 기본 기준 (오름차순). 다른 통화는 `Currency.netWorthTiers` 참조
const defaultNetWorthThresholds = [
  50000000,
  100000000,
  300000000,
  500000000,
  1000000000,
];

/// FIRE 진행률 기준 (%)
const fireProgressMilestones = [25, 50, 75, 100];

/// 연속 기록 기준 (개월)
const streakMilestones = [
  (months: 3, key: 'streak_3mo'),
  (months: 6, key: 'streak_6mo'),
  (months: 12, key: 'streak_12mo'),
];

/// 새로 달성한 마일스톤 키 목록을 반환한다. 이미 달성한 키는 제외.
///
/// [recordedYms]: 기록된 스냅샷 연월(yyyymm) 목록 (이번 달 포함)
/// [ym]: 이번 스냅샷 연월
/// [netWorthThresholds]: 순자산 구간 기준 5개 (통화 최소 단위, 오름차순).
///   기본값은 원화 기준
List<String> evaluateMilestones({
  required int netWorth,
  required int fireNumber,
  required List<int> recordedYms,
  required int ym,
  required Set<String> achievedKeys,
  List<int> netWorthThresholds = defaultNetWorthThresholds,
}) {
  assert(netWorthThresholds.length == netWorthMilestoneKeys.length);
  final newlyAchieved = <String>[];

  void add(String key) {
    if (!achievedKeys.contains(key)) newlyAchieved.add(key);
  }

  for (final (index, threshold) in netWorthThresholds.indexed) {
    if (netWorth >= threshold) add(netWorthMilestoneKeys[index]);
  }

  if (fireNumber > 0) {
    for (final percent in fireProgressMilestones) {
      if (netWorth * 100 >= fireNumber * percent) add('fire_${percent}pct');
    }
  }

  // 연속 기록: 이번 달부터 거꾸로 이어진 개월 수
  final recorded = recordedYms.toSet();
  var streak = 0;
  var cursor = ym;
  while (recorded.contains(cursor)) {
    streak++;
    cursor = _previousYm(cursor);
  }
  for (final entry in streakMilestones) {
    if (streak >= entry.months) add(entry.key);
  }

  return newlyAchieved;
}

int _previousYm(int ym) {
  final month = ym % 100;
  return month == 1 ? ym - 100 + 11 : ym - 1;
}
