import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../engine/engine.dart';
import '../db/database.dart';
import '../plan_input_json.dart';

/// 저장된 시나리오 1건
typedef ScenarioEntry = ({String id, String name, PlanInput input});

/// 시뮬 놀이터 시나리오 저장 (S4).
///
/// 무료는 1개만 유지, 프리미엄은 여러 개 저장 (PRD S4). 무료/유료 정책은
/// 호출부(앱 레이어)에서 [keepExisting]으로 결정한다.
class ScenarioRepository {
  static const _uuid = Uuid();

  final AppDatabase _db;

  ScenarioRepository(this._db);

  /// 시나리오 저장.
  /// [keepExisting]=false(무료): 기존을 정리하고 1개만 유지.
  /// [keepExisting]=true(프리미엄): 기존을 두고 추가.
  Future<void> save({
    required String name,
    required PlanInput input,
    required bool keepExisting,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (!keepExisting) {
        await (_db.update(_db.scenarios)..where((t) => t.deletedAt.isNull()))
            .write(ScenariosCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ));
      }
      await _db.into(_db.scenarios).insert(ScenariosCompanion.insert(
            id: _uuid.v4(),
            name: name,
            paramsJson: jsonEncode(planInputToJson(input)),
            createdAt: now,
            updatedAt: now,
          ));
    });
  }

  /// 저장된 시나리오 목록 (최신순)
  Future<List<ScenarioEntry>> list() async {
    final rows = await (_db.select(_db.scenarios)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
    return [
      for (final r in rows)
        (
          id: r.id,
          name: r.name,
          input: planInputFromJson(
              jsonDecode(r.paramsJson) as Map<String, dynamic>),
        ),
    ];
  }

  /// 특정 시나리오 삭제 (soft delete)
  Future<void> delete(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.scenarios)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(ScenariosCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// 가장 최근 시나리오 1개 (무료 불러오기·초기 존재 확인용)
  Future<ScenarioEntry?> loadSingle() async {
    final entries = await list();
    return entries.isEmpty ? null : entries.first;
  }
}
