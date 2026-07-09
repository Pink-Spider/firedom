import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/ym.dart';
import '../../engine/engine.dart';
import '../db/database.dart';

class PlanRepository {
  static const _uuid = Uuid();

  final AppDatabase _db;

  PlanRepository(this._db);

  Stream<Plan?> watchActivePlan() {
    return (_db.select(_db.plans)
          ..where((t) => t.deletedAt.isNull() & t.isActive.equals(true))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<Plan?> getActivePlan() {
    return (_db.select(_db.plans)
          ..where((t) => t.deletedAt.isNull() & t.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 새 계획 생성. 활성 계획은 전체에서 1개 — 기존 활성은 비활성화 (B1).
  Future<Plan> createPlan({
    required PlanInput input,
    required int birthYm,
    required int startedYm,
    String fireType = 'custom',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    return _db.transaction(() async {
      await (_db.update(_db.plans)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull()))
          .write(PlansCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
      ));
      await _db.into(_db.plans).insert(PlansCompanion.insert(
            id: id,
            revisionGroup: id,
            isActive: const Value(true),
            fireType: Value(fireType),
            birthYm: birthYm,
            currentAssets: input.currentAssets,
            monthlySaving: input.monthlySaving,
            realReturnBp: input.realReturnBp,
            volatilityBp: input.volatilityBp,
            monthlySpendRetire: input.monthlySpendRetire,
            swrBp: Value(input.swrBp),
            lifeExpectancy: Value(input.lifeExpectancy),
            npsMonthly: Value(input.nps?.monthlyAmount),
            npsStartAge: Value(input.nps?.startAge),
            startedYm: startedYm,
            createdAt: now,
            updatedAt: now,
          ));
      return (_db.select(_db.plans)..where((t) => t.id.equals(id)))
          .getSingle();
    });
  }

  /// 계획 수정 = 같은 revision_group에 새 리비전 append (B1).
  /// 궤도 기준점(started_ym·birth_ym·수립 시점 자산)은 유지하고 가정만 바꾼다.
  Future<Plan> revisePlan({
    required Plan base,
    required PlanInput input,
    String? fireType,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    return _db.transaction(() async {
      await (_db.update(_db.plans)
            ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull()))
          .write(PlansCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
      ));
      await _db.into(_db.plans).insert(PlansCompanion.insert(
            id: id,
            revisionGroup: base.revisionGroup,
            isActive: const Value(true),
            fireType: Value(fireType ?? base.fireType),
            birthYm: base.birthYm,
            currentAssets: base.currentAssets,
            monthlySaving: input.monthlySaving,
            realReturnBp: input.realReturnBp,
            volatilityBp: input.volatilityBp,
            monthlySpendRetire: input.monthlySpendRetire,
            swrBp: Value(input.swrBp),
            lifeExpectancy: Value(input.lifeExpectancy),
            npsMonthly: Value(input.nps?.monthlyAmount),
            npsStartAge: Value(input.nps?.startAge),
            startedYm: base.startedYm,
            createdAt: now,
            updatedAt: now,
          ));
      return (_db.select(_db.plans)..where((t) => t.id.equals(id)))
          .getSingle();
    });
  }

  /// 같은 계획의 리비전 이력 (홈 궤도 차트의 "계획 변경 마커" 원천)
  Stream<List<Plan>> watchRevisions(String revisionGroup) {
    return _revisionsQuery(revisionGroup).watch();
  }

  Future<List<Plan>> getRevisions(String revisionGroup) {
    return _revisionsQuery(revisionGroup).get();
  }

  SimpleSelectStatement<$PlansTable, Plan> _revisionsQuery(
      String revisionGroup) {
    return _db.select(_db.plans)
      ..where(
          (t) => t.revisionGroup.equals(revisionGroup) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
  }
}

/// Plan 행 → 엔진 입력. age0는 궤도 t=0(= started_ym) 시점 나이 (R2).
PlanInput planInputOf(Plan row) {
  return PlanInput(
    age0: ageFromBirthYm(row.birthYm, row.startedYm),
    currentAssets: row.currentAssets,
    monthlySaving: row.monthlySaving,
    realReturnBp: row.realReturnBp,
    monthlySpendRetire: row.monthlySpendRetire,
    swrBp: row.swrBp,
    lifeExpectancy: row.lifeExpectancy,
    nps: row.npsMonthly == null
        ? null
        : NpsInput(
            monthlyAmount: row.npsMonthly!,
            startAge: row.npsStartAge ?? 65,
          ),
    volatilityBp: row.volatilityBp,
  );
}
