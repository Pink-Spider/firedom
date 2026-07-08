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
