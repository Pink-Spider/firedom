import '../core/currency.dart';
import '../engine/engine.dart';
import 'db/database.dart';
import 'repositories/milestone_repository.dart';
import 'repositories/plan_repository.dart';
import 'repositories/settings_store.dart';
import 'repositories/snapshot_repository.dart';

/// 스냅샷 저장 직후 마일스톤 판정·기록 (B1: 판정은 엔진, 결과만 저장).
/// 반환: 이번에 새로 달성한 키 목록.
Future<List<String>> evaluateAndRecordMilestones(
  AppDatabase db, {
  required int ym,
}) async {
  final snapshotRepository = SnapshotRepository(db);
  final milestoneRepository = MilestoneRepository(db);

  final snapshot = await snapshotRepository.getByYm(ym);
  if (snapshot == null) return const [];

  final summaries = await snapshotRepository.getSummaries();
  SnapshotSummary? current;
  for (final summary in summaries) {
    if (summary.ym == ym) current = summary;
  }
  if (current == null) return const [];

  final plan = await PlanRepository(db).getActivePlan();
  final fireNumber =
      plan == null ? 0 : solvePlan(planInputOf(plan)).fireNumber;

  final currency = Currency.fromCode(
      await SettingsStore(db).get<String>(SettingKeys.currency));
  final newKeys = evaluateMilestones(
    netWorth: current.netWorth,
    fireNumber: fireNumber,
    recordedYms: [for (final summary in summaries) summary.ym],
    ym: ym,
    achievedKeys: await milestoneRepository.achievedKeys(),
    netWorthThresholds: currency.netWorthTiers,
  );
  for (final key in newKeys) {
    await milestoneRepository.record(
      key: key,
      achievedYm: ym,
      snapshotId: snapshot.id,
    );
  }
  return newKeys;
}
