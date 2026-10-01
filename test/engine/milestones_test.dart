import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('마일스톤 판정 (B1)', () {
    test('순자산 구간: 1.2억 → 5,000만·1억 돌파 (FIRE 13%는 미달성)', () {
      final keys = evaluateMilestones(
        netWorth: 120000000,
        fireNumber: 900000000,
        recordedYms: [202607],
        ym: 202607,
        achievedKeys: {},
      );
      expect(keys, containsAll(['net_worth_50m', 'net_worth_100m']));
      expect(keys.where((k) => k.startsWith('fire_')), isEmpty);
    });

    test('FIRE 진행률: 2.5억/9억 = 27% → 25% 달성', () {
      final keys = evaluateMilestones(
        netWorth: 250000000,
        fireNumber: 900000000,
        recordedYms: [202607],
        ym: 202607,
        achievedKeys: {'net_worth_50m', 'net_worth_100m'},
      );
      expect(keys, contains('fire_25pct'));
      expect(keys, isNot(contains('net_worth_300m')));
      expect(keys, isNot(contains('net_worth_100m'))); // 이미 달성
    });

    test('FIRE 100%: 목표 도달', () {
      final keys = evaluateMilestones(
        netWorth: 900000000,
        fireNumber: 900000000,
        recordedYms: [202607],
        ym: 202607,
        achievedKeys: {},
      );
      expect(keys, contains('fire_100pct'));
    });

    test('연속 기록: 연도 경계를 넘어 3개월 → streak_3mo', () {
      final keys = evaluateMilestones(
        netWorth: 1000,
        fireNumber: 900000000,
        recordedYms: [202511, 202512, 202601],
        ym: 202601,
        achievedKeys: {},
      );
      expect(keys, contains('streak_3mo'));
      expect(keys, isNot(contains('streak_6mo')));
    });

    test('중간에 빈 달이 있으면 연속이 끊긴다', () {
      final keys = evaluateMilestones(
        netWorth: 1000,
        fireNumber: 900000000,
        recordedYms: [202603, 202605, 202606], // 4월 공백
        ym: 202606,
        achievedKeys: {},
      );
      expect(keys, isNot(contains('streak_3mo')));
    });

    test('이미 달성한 키는 다시 반환하지 않는다 (중복 방지)', () {
      final keys = evaluateMilestones(
        netWorth: 120000000,
        fireNumber: 900000000,
        recordedYms: [202607],
        ym: 202607,
        achievedKeys: {'net_worth_50m', 'net_worth_100m'},
      );
      expect(keys, isEmpty);
    });

    test('fireNumber 0이면 진행률 판정 생략 (0 나눗셈 방지)', () {
      final keys = evaluateMilestones(
        netWorth: 100000000,
        fireNumber: 0,
        recordedYms: [202607],
        ym: 202607,
        achievedKeys: {},
      );
      expect(keys.where((k) => k.startsWith('fire_')), isEmpty);
    });
  });

  group('netWorthThresholds — 통화별 기준 주입', () {
    test('USD 기준(센트)으로 \$100k 돌파 판정', () {
      final keys = evaluateMilestones(
        netWorth: 10000000, // \$100,000
        fireNumber: 0,
        recordedYms: const [202607],
        ym: 202607,
        achievedKeys: const {},
        netWorthThresholds: const [
          5000000,
          10000000,
          25000000,
          50000000,
          100000000,
        ],
      );
      expect(keys, containsAll(['net_worth_50m', 'net_worth_100m']));
      expect(keys, isNot(contains('net_worth_300m')));
    });

    test('기본값은 원화 기준', () {
      expect(defaultNetWorthThresholds.length, netWorthMilestoneKeys.length);
      final keys = evaluateMilestones(
        netWorth: 50000000,
        fireNumber: 0,
        recordedYms: const [202607],
        ym: 202607,
        achievedKeys: const {},
      );
      expect(keys, contains('net_worth_50m'));
    });
  });
}
