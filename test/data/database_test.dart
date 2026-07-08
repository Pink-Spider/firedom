import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

/// 스키마 규약(B0·B3)과 리포지토리 동작 검증.
///
/// 마이그레이션 스캐폴드(B5): schemaVersion을 올릴 때마다
/// 이전 버전 fixture → onUpgrade → 무결성 검증 테스트를 이 파일 옆에 추가한다.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('스키마 규약 (B0·B3)', () {
    test('snapshots.ym 부분 유니크: 동일 ym 중복 거부, soft delete 후 허용', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SnapshotsCompanion snapshotOf(String id) => SnapshotsCompanion.insert(
            id: id,
            ym: 202607,
            createdAt: now,
            updatedAt: now,
          );

      await db.into(db.snapshots).insert(snapshotOf('a'));
      await expectLater(
        db.into(db.snapshots).insert(snapshotOf('b')),
        throwsA(isA<SqliteException>()),
      );

      // soft delete하면 같은 ym으로 새 행 삽입 가능
      await (db.update(db.snapshots)..where((t) => t.id.equals('a'))).write(
        SnapshotsCompanion(deletedAt: Value(now)),
      );
      await db.into(db.snapshots).insert(snapshotOf('b'));
    });

    test('schemaVersion = 1', () {
      expect(db.schemaVersion, 1);
    });
  });

  group('PlanRepository', () {
    test('createPlan: 활성 계획은 전체에서 1개', () async {
      final repo = PlanRepository(db);
      const input = PlanInput(
        age0: 35,
        currentAssets: 100000000,
        monthlySaving: 2000000,
        realReturnBp: 400,
        monthlySpendRetire: 3000000,
      );

      final first = await repo.createPlan(
          input: input, birthYm: 199107, startedYm: 202607);
      final second = await repo.createPlan(
          input: input.copyWith(monthlySaving: 2500000),
          birthYm: 199107,
          startedYm: 202607);

      final active = await repo.getActivePlan();
      expect(active!.id, second.id);
      expect(active.monthlySaving, 2500000);

      final firstRow = await (db.select(db.plans)
            ..where((t) => t.id.equals(first.id)))
          .getSingle();
      expect(firstRow.isActive, isFalse);
    });

    test('planInputOf: age0는 궤도 t=0(started_ym) 시점 나이', () {
      final plan = Plan(
        id: 'p',
        revisionGroup: 'p',
        isActive: true,
        fireType: 'custom',
        birthYm: 199107,
        currentAssets: 100000000,
        monthlySaving: 2000000,
        realReturnBp: 400,
        volatilityBp: 1200,
        monthlySpendRetire: 3000000,
        swrBp: 400,
        lifeExpectancy: 90,
        npsMonthly: null,
        npsStartAge: null,
        startedYm: 202607,
        createdAt: 0,
        updatedAt: 0,
        deletedAt: null,
      );
      final input = planInputOf(plan);
      expect(input.age0, 35); // 1991.07 → 2026.07 = 만 35세
      expect(input.nps, isNull);
    });
  });

  group('SnapshotRepository', () {
    test('ensureDefaultAccounts: 기본 6항목, 멱등', () async {
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      expect(accounts.length, 6);
      expect(accounts.first.name, '예금');
      expect(accounts.where((a) => a.isLiability).single.name, '대출');

      final again = await repo.ensureDefaultAccounts();
      expect(again.length, 6); // 중복 생성 없음
    });

    test('saveSnapshot: 순자산 = 항목 합, 같은 ym 재저장은 교체(소급 수정)', () async {
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      final deposit = accounts[0].id; // 예금
      final loan = accounts[4].id; // 대출 (부채)

      await repo.saveSnapshot(
        ym: 202607,
        amountsByAccountId: {deposit: 50000000, loan: -20000000},
        income: 5000000,
        expense: 3000000,
      );

      var summaries = await repo.watchSummaries().first;
      expect(summaries.single.netWorth, 30000000);
      expect(summaries.single.snapshot.income, 5000000);

      // 소급 수정: 항목 교체 + 스냅샷 중복 없음
      await repo.saveSnapshot(
        ym: 202607,
        amountsByAccountId: {deposit: 60000000},
        income: 5000000,
        expense: 2500000,
      );
      summaries = await repo.watchSummaries().first;
      expect(summaries.length, 1);
      expect(summaries.single.netWorth, 60000000);
      expect(summaries.single.snapshot.expense, 2500000);
    });

    test('latestAmountsBefore: 전월 복사 기본값', () async {
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      final deposit = accounts[0].id;
      final equity = accounts[1].id;

      await repo.saveSnapshot(
        ym: 202605,
        amountsByAccountId: {deposit: 10000000, equity: 5000000},
      );
      await repo.saveSnapshot(
        ym: 202606,
        amountsByAccountId: {deposit: 12000000, equity: 6000000},
      );

      // 202607의 기본값은 직전(202606) 항목
      final amounts = await repo.latestAmountsBefore(202607);
      expect(amounts, {deposit: 12000000, equity: 6000000});

      // 첫 기록이면 빈 맵
      expect(await repo.latestAmountsBefore(202605), isEmpty);
    });

    test('include_in_fire=0 항목은 순자산에서 제외 (거주 부동산 토글)', () async {
      final repo = SnapshotRepository(db);
      final home = await repo.createAccount(
        name: '거주 아파트',
        assetClass: 'real_estate',
        includeInFire: false,
      );
      final cash = await repo.createAccount(name: '현금', assetClass: 'cash');

      await repo.saveSnapshot(
        ym: 202607,
        amountsByAccountId: {home.id: 900000000, cash.id: 10000000},
      );

      final summaries = await repo.watchSummaries().first;
      expect(summaries.single.netWorth, 10000000);
    });

    test('빈 달은 공백: 기록된 달만 반환 (보간 금지)', () async {
      final repo = SnapshotRepository(db);
      final accounts = await repo.ensureDefaultAccounts();
      await repo.saveSnapshot(
          ym: 202603, amountsByAccountId: {accounts[0].id: 1000});
      await repo.saveSnapshot(
          ym: 202607, amountsByAccountId: {accounts[0].id: 2000});

      final summaries = await repo.watchSummaries().first;
      expect(summaries.map((s) => s.ym), [202603, 202607]);
    });
  });

  group('SettingsStore', () {
    test('set/get/watch — JSON 왕복', () async {
      final store = SettingsStore(db);
      expect(await store.get<bool>(SettingKeys.maskAmounts), isNull);

      await store.set(SettingKeys.maskAmounts, true);
      expect(await store.get<bool>(SettingKeys.maskAmounts), isTrue);

      await store.set(SettingKeys.maskAmounts, false);
      expect(await store.watch<bool>(SettingKeys.maskAmounts).first, isFalse);
    });
  });

  group('UUID PK 규약', () {
    test('생성되는 id는 UUID v4 형식', () async {
      final repo = SnapshotRepository(db);
      final account =
          await repo.createAccount(name: 'ISA', assetClass: 'equity');
      expect(Uuid.isValidUUID(fromString: account.id), isTrue);
    });
  });

  group('ym 유틸', () {
    test('가감/차이/나이 계산', () {
      expect(ymAddMonths(202607, 6), 202701);
      expect(ymAddMonths(202601, -1), 202512);
      expect(ymDiffMonths(202607, 202707), 12);
      expect(ageFromBirthYm(199107, 202607), 35);
      expect(ageFromBirthYm(199108, 202607), 34); // 생일 전
      expect(birthYmFromAge(35, 202607), 199107);
    });
  });
}
