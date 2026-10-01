import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

/// 스냅샷 + 파생 순자산 (순자산은 저장하지 않는다 — B1)
class SnapshotSummary {
  final Snapshot snapshot;

  /// include_in_fire=1 항목의 합 (부채는 음수로 저장되므로 단순 합)
  final int netWorth;

  const SnapshotSummary({required this.snapshot, required this.netWorth});

  int get ym => snapshot.ym;
}

/// S8 첫 셋업 기본 항목 (PRD)
const defaultAccountSeeds = [
  (name: '예금', assetClass: 'cash', isLiability: false),
  (name: '주식', assetClass: 'equity', isLiability: false),
  (name: '연금계좌', assetClass: 'pension', isLiability: false),
  (name: '부동산', assetClass: 'real_estate', isLiability: false),
  (name: '대출', assetClass: 'other', isLiability: true),
  (name: '기타', assetClass: 'other', isLiability: false),
];

class SnapshotRepository {
  static const _uuid = Uuid();

  final AppDatabase _db;

  SnapshotRepository(this._db);

  // ── 자산 항목 (accounts) ──────────────────────────────────

  Stream<List<Account>> watchAccounts() {
    return (_db.select(_db.accounts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<List<Account>> getAccounts() {
    return (_db.select(_db.accounts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  /// 첫 사용 시 기본 항목 셋업. 이미 항목이 있으면 그대로 반환 (멱등).
  ///
  /// [names]: 기본 항목 이름 6개 ([defaultAccountSeeds] 순서, UI 언어별).
  /// null이면 한국어 시드 이름을 쓴다.
  Future<List<Account>> ensureDefaultAccounts({List<String>? names}) async {
    assert(names == null || names.length == defaultAccountSeeds.length);
    final existing = await getAccounts();
    if (existing.isNotEmpty) return existing;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.batch((batch) {
      for (final (index, seed) in defaultAccountSeeds.indexed) {
        batch.insert(
          _db.accounts,
          AccountsCompanion.insert(
            id: _uuid.v4(),
            name: names?[index] ?? seed.name,
            assetClass: seed.assetClass,
            isLiability: Value(seed.isLiability),
            sortOrder: Value(index),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
    return getAccounts();
  }

  Future<Account> createAccount({
    required String name,
    required String assetClass,
    bool isLiability = false,
    String accountType = 'normal',
    bool includeInFire = true,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final maxOrder = await getAccounts()
        .then((all) => all.isEmpty ? 0 : all.last.sortOrder + 1);
    await _db.into(_db.accounts).insert(AccountsCompanion.insert(
          id: id,
          name: name,
          assetClass: assetClass,
          accountType: Value(accountType),
          isLiability: Value(isLiability),
          includeInFire: Value(includeInFire),
          sortOrder: Value(maxOrder),
          createdAt: now,
          updatedAt: now,
        ));
    return (_db.select(_db.accounts)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> renameAccount(String id, String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(name: Value(name), updatedAt: Value(now)),
    );
  }

  Future<void> softDeleteAccount(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ── 스냅샷 ────────────────────────────────────────────────

  Future<Snapshot?> getByYm(int ym) {
    return (_db.select(_db.snapshots)
          ..where((t) => t.ym.equals(ym) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<SnapshotItem>> itemsOf(String snapshotId) {
    return (_db.select(_db.snapshotItems)
          ..where(
              (t) => t.snapshotId.equals(snapshotId) & t.deletedAt.isNull()))
        .get();
  }

  /// 전월 복사 기본값 (PRD S8): ym 이전 가장 최근 스냅샷의 항목별 금액
  Future<Map<String, int>> latestAmountsBefore(int ym) async {
    final previous = await (_db.select(_db.snapshots)
          ..where((t) => t.deletedAt.isNull() & t.ym.isSmallerThanValue(ym))
          ..orderBy([
            (t) => OrderingTerm(expression: t.ym, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
    if (previous == null) return {};
    final items = await itemsOf(previous.id);
    return {for (final item in items) item.accountId: item.amount};
  }

  /// 원자적 저장 (PRD S8). 동일 ym이 있으면 헤더 갱신 + 항목 교체(소급 수정).
  Future<Snapshot> saveSnapshot({
    required int ym,
    required Map<String, int> amountsByAccountId,
    int? income,
    int? expense,
    String? note,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      var snapshot = await getByYm(ym);
      if (snapshot == null) {
        final id = _uuid.v4();
        await _db.into(_db.snapshots).insert(SnapshotsCompanion.insert(
              id: id,
              ym: ym,
              income: Value(income),
              expense: Value(expense),
              note: Value(note),
              createdAt: now,
              updatedAt: now,
            ));
      } else {
        await (_db.update(_db.snapshots)
              ..where((t) => t.id.equals(snapshot!.id)))
            .write(SnapshotsCompanion(
          income: Value(income),
          expense: Value(expense),
          note: Value(note),
          updatedAt: Value(now),
        ));
        await (_db.update(_db.snapshotItems)
              ..where((t) =>
                  t.snapshotId.equals(snapshot!.id) & t.deletedAt.isNull()))
            .write(SnapshotItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ));
      }
      snapshot = (await getByYm(ym))!;
      await _db.batch((batch) {
        for (final entry in amountsByAccountId.entries) {
          batch.insert(
            _db.snapshotItems,
            SnapshotItemsCompanion.insert(
              id: _uuid.v4(),
              snapshotId: snapshot!.id,
              accountId: entry.key,
              amount: entry.value,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
      return snapshot;
    });
  }

  /// 최신 스냅샷의 자산군별 합계 (S6 자산배분).
  /// FIRE 포함 자산의 양수 항목만 — 부채(음수)는 배분 도넛에서 제외.
  Stream<({int ym, Map<String, int> byClass})?> watchLatestAllocation() {
    final query = _db.select(_db.snapshots).join([
      innerJoin(
        _db.snapshotItems,
        _db.snapshotItems.snapshotId.equalsExp(_db.snapshots.id) &
            _db.snapshotItems.deletedAt.isNull(),
      ),
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.snapshotItems.accountId),
      ),
    ])
      ..where(_db.snapshots.deletedAt.isNull());

    return query.watch().map((rows) {
      var latestYm = -1;
      for (final row in rows) {
        final ym = row.readTable(_db.snapshots).ym;
        if (ym > latestYm) latestYm = ym;
      }
      if (latestYm < 0) return null;

      final byClass = <String, int>{};
      for (final row in rows) {
        if (row.readTable(_db.snapshots).ym != latestYm) continue;
        final account = row.readTable(_db.accounts);
        final amount = row.readTable(_db.snapshotItems).amount;
        if (!account.includeInFire || amount <= 0) continue;
        byClass[account.assetClass] =
            (byClass[account.assetClass] ?? 0) + amount;
      }
      return (ym: latestYm, byClass: byClass);
    });
  }

  /// ym 오름차순 스냅샷 + 순자산. 빈 달은 항목이 없으므로 자연히 공백 (보간 금지).
  Stream<List<SnapshotSummary>> watchSummaries() {
    return _summariesQuery().watch().map(_mapSummaryRows);
  }

  Future<List<SnapshotSummary>> getSummaries() async {
    return _mapSummaryRows(await _summariesQuery().get());
  }

  JoinedSelectStatement<HasResultSet, dynamic> _summariesQuery() {
    return _db.select(_db.snapshots).join([
      leftOuterJoin(
        _db.snapshotItems,
        _db.snapshotItems.snapshotId.equalsExp(_db.snapshots.id) &
            _db.snapshotItems.deletedAt.isNull(),
      ),
      leftOuterJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.snapshotItems.accountId),
      ),
    ])
      ..where(_db.snapshots.deletedAt.isNull())
      ..orderBy([OrderingTerm(expression: _db.snapshots.ym)]);
  }

  List<SnapshotSummary> _mapSummaryRows(List<TypedResult> rows) {
    final byId = <String, Snapshot>{};
    final netById = <String, int>{};
    for (final row in rows) {
      final snapshot = row.readTable(_db.snapshots);
      byId[snapshot.id] = snapshot;
      final item = row.readTableOrNull(_db.snapshotItems);
      final account = row.readTableOrNull(_db.accounts);
      // 항목이 참조하는 계정이 이후 삭제됐어도 과거 기록의 순자산은 보존한다
      if (item != null && account != null && account.includeInFire) {
        netById[snapshot.id] = (netById[snapshot.id] ?? 0) + item.amount;
      }
    }
    return [
      for (final entry in byId.entries)
        SnapshotSummary(
          snapshot: entry.value,
          netWorth: netById[entry.key] ?? 0,
        ),
    ];
  }
}
