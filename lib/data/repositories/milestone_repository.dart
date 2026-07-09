import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// 달성 기록 (B1) — "달성 순간"의 이벤트 로그
class MilestoneRepository {
  static const _uuid = Uuid();

  final AppDatabase _db;

  MilestoneRepository(this._db);

  Stream<List<Milestone>> watchAll() {
    return (_db.select(_db.milestones)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.achievedYm),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  Future<Set<String>> achievedKeys() async {
    final rows = await (_db.select(_db.milestones)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return {for (final row in rows) row.milestoneKey};
  }

  Future<void> record({
    required String key,
    required int achievedYm,
    String? snapshotId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.milestones).insert(MilestonesCompanion.insert(
          id: _uuid.v4(),
          milestoneKey: key,
          achievedYm: achievedYm,
          snapshotId: Value(snapshotId),
          createdAt: now,
          updatedAt: now,
        ));
  }
}
