import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/home_widget_sync.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Plan _plan({int currentAssets = 100000000, int startedYm = 202607}) {
  return Plan(
    id: 'p',
    revisionGroup: 'p',
    isActive: true,
    fireType: 'custom',
    birthYm: 199107,
    currentAssets: currentAssets,
    monthlySaving: 2000000,
    realReturnBp: 400,
    volatilityBp: 1200,
    monthlySpendRetire: 3000000,
    swrBp: 400,
    lifeExpectancy: 90,
    npsMonthly: null,
    npsStartAge: null,
    startedYm: startedYm,
    createdAt: 0,
    updatedAt: 0,
    deletedAt: null,
  );
}

SnapshotSummary _summary(int ym, int netWorth) {
  return SnapshotSummary(
    snapshot: Snapshot(
      id: 's$ym',
      ym: ym,
      income: null,
      expense: null,
      note: null,
      createdAt: 0,
      updatedAt: 0,
      deletedAt: null,
    ),
    netWorth: netWorth,
  );
}

void main() {
  group('W1 위젯 페이로드', () {
    test('계획 없음 → 온보딩 유도 문구', () {
      final payload = buildWidgetPayload(
        plan: null,
        summaries: const [],
        currentYm: 202607,
      );
      expect(payload.ddayText, '계획을 만들어보세요');
      expect(payload.progressPercent, 0);
    });

    test('G1 계획, 스냅샷 없음: D-day 19년 3개월 · 진행률 11%', () {
      final payload = buildWidgetPayload(
        plan: _plan(),
        summaries: const [],
        currentYm: 202607,
      );
      expect(payload.ddayText, '자유까지 19년 3개월');
      expect(payload.progressPercent, 11); // 1억 / 9억
      expect(payload.deviationText, ''); // 스냅샷 <2개
    });

    test('스냅샷 2개, 궤도보다 앞 → 편차 배지', () {
      final payload = buildWidgetPayload(
        plan: _plan(startedYm: 202605),
        summaries: [
          _summary(202606, 105000000),
          _summary(202607, 115000000), // 경과 2개월, 곡선 ~6개월 지점 수준
        ],
        currentYm: 202607,
      );
      expect(payload.deviationText, contains('계획보다'));
      expect(payload.deviationText, contains('앞'));
    });

    test('금액은 절대 포함하지 않는다 (프라이버시)', () {
      final payload = buildWidgetPayload(
        plan: _plan(),
        summaries: [_summary(202606, 105000000), _summary(202607, 110000000)],
        currentYm: 202607,
      );
      for (final text in [payload.ddayText, payload.deviationText]) {
        expect(text.contains('원'), isFalse);
        expect(text.contains('억'), isFalse);
        expect(text.contains(','), isFalse);
      }
    });
  });
}
