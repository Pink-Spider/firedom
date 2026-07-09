import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../engine/engine.dart';
import '../db/database.dart';
import '../plan_input_json.dart';

/// 시뮬 놀이터 시나리오 저장 (S4). 무료 1개 제한은 여기(앱 레이어)서 강제.
class ScenarioRepository {
  static const _uuid = Uuid();

  final AppDatabase _db;

  ScenarioRepository(this._db);

  /// 무료 정책: 기존 시나리오를 정리하고 1개만 유지 (PRD S4)
  Future<void> saveSingle({
    required String name,
    required PlanInput input,
  }) {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.scenarios)
            ..where((t) => t.deletedAt.isNull()))
          .write(ScenariosCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
      await _db.into(_db.scenarios).insert(ScenariosCompanion.insert(
            id: _uuid.v4(),
            name: name,
            paramsJson: jsonEncode(planInputToJson(input)),
            createdAt: now,
            updatedAt: now,
          ));
    });
  }

  Future<({String name, PlanInput input})?> loadSingle() async {
    final row = await (_db.select(_db.scenarios)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return (
      name: row.name,
      input: planInputFromJson(
          jsonDecode(row.paramsJson) as Map<String, dynamic>),
    );
  }
}
