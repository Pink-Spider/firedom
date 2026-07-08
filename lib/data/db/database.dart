import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Plans,
  Accounts,
  Snapshots,
  SnapshotItems,
  Scenarios,
  Milestones,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // B3 인덱스 — 부분 인덱스는 Drift 테이블 API 미지원이라 SQL로 생성
          await customStatement(
            'CREATE UNIQUE INDEX idx_snapshots_ym ON snapshots (ym) '
            'WHERE deleted_at IS NULL',
          );
          await customStatement(
            'CREATE INDEX idx_snapshot_items_snapshot '
            'ON snapshot_items (snapshot_id)',
          );
          await customStatement(
            'CREATE INDEX idx_snapshot_items_account '
            'ON snapshot_items (account_id)',
          );
          await customStatement(
            'CREATE INDEX idx_plans_active ON plans (is_active) '
            'WHERE deleted_at IS NULL',
          );
        },
        // B5: 마이그레이션은 추가적(additive) 우선.
        // 버전을 올릴 때마다 from→to 단계별 마이그레이션과
        // 이전 버전 fixture 기반 테스트를 함께 추가할 것 (test/data/).
        onUpgrade: (m, from, to) async {},
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
