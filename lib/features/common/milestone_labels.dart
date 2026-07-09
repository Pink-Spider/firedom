/// 마일스톤 키 → 표시 문구
library;

const _labels = {
  'net_worth_50m': '순자산 5,000만원 돌파! 🎉',
  'net_worth_100m': '순자산 1억 돌파! 🎉',
  'net_worth_300m': '순자산 3억 돌파! 🎉',
  'net_worth_500m': '순자산 5억 돌파! 🎉',
  'net_worth_1b': '순자산 10억 돌파! 🎉',
  'fire_25pct': 'FIRE 목표 25% 달성! 🔥',
  'fire_50pct': 'FIRE 목표 절반 달성! 🔥',
  'fire_75pct': 'FIRE 목표 75% 달성! 🔥',
  'fire_100pct': 'FIRE 목표 도달! 🏆',
  'streak_3mo': '3개월 연속 기록 🔥',
  'streak_6mo': '6개월 연속 기록 🔥🔥',
  'streak_12mo': '1년 연속 기록 🏆',
};

String milestoneLabel(String key) => _labels[key] ?? '마일스톤 달성! 🎉';
