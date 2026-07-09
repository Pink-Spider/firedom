import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/milestone_repository.dart';
import '../repositories/plan_repository.dart';
import '../repositories/scenario_repository.dart';
import '../repositories/settings_store.dart';
import '../repositories/snapshot_repository.dart';
import 'database.dart';

/// main()에서 실제 DB로 override한다 (테스트는 in-memory).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider는 main()에서 override'),
);

/// 기동 시점의 활성 계획 존재 여부 — 라우터 시작 위치 결정용 (main()에서 override).
final hasActivePlanAtLaunchProvider = Provider<bool>(
  (ref) => throw UnimplementedError(
      'hasActivePlanAtLaunchProvider는 main()에서 override'),
);

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(databaseProvider)),
);

final snapshotRepositoryProvider = Provider<SnapshotRepository>(
  (ref) => SnapshotRepository(ref.watch(databaseProvider)),
);

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(databaseProvider)),
);

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => ScenarioRepository(ref.watch(databaseProvider)),
);

final milestoneRepositoryProvider = Provider<MilestoneRepository>(
  (ref) => MilestoneRepository(ref.watch(databaseProvider)),
);

final milestonesProvider = StreamProvider<List<Milestone>>(
  (ref) => ref.watch(milestoneRepositoryProvider).watchAll(),
);

final activePlanRowProvider = StreamProvider<Plan?>(
  (ref) => ref.watch(planRepositoryProvider).watchActivePlan(),
);

/// 활성 계획의 리비전 이력 (계획 변경 마커용)
final activePlanRevisionsProvider = StreamProvider<List<Plan>>((ref) {
  final active = ref.watch(activePlanRowProvider).value;
  if (active == null) return Stream.value(const <Plan>[]);
  return ref
      .watch(planRepositoryProvider)
      .watchRevisions(active.revisionGroup);
});

final snapshotSummariesProvider = StreamProvider<List<SnapshotSummary>>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchSummaries(),
);

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchAccounts(),
);

/// 금액 가림(●●●) 상태 — settings 테이블 연동
final maskAmountsProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(settingsStoreProvider)
      .watch<bool>(SettingKeys.maskAmounts)
      .map((value) => value ?? false),
);

/// 최신 스냅샷의 자산군별 배분 (S6)
final latestAllocationProvider =
    StreamProvider<({int ym, Map<String, int> byClass})?>(
  (ref) => ref.watch(snapshotRepositoryProvider).watchLatestAllocation(),
);

/// 목표 자산 배분 (자산군 → %) — settings 테이블
final targetAllocationProvider = StreamProvider<Map<String, int>>(
  (ref) => ref
      .watch(settingsStoreProvider)
      .watch<Map<String, dynamic>>(SettingKeys.targetAllocation)
      .map((value) =>
          value == null ? const {} : value.map((k, v) => MapEntry(k, v as int))),
);
