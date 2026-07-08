import 'dart:convert';

import '../db/database.dart';

/// settings k/v 테이블 접근자 (B1). 값은 JSON 인코딩.
class SettingsStore {
  final AppDatabase _db;

  SettingsStore(this._db);

  Future<void> set(String key, Object? value) {
    return _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: key,
            value: jsonEncode(value),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<T?> get<T>(String key) async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row == null ? null : jsonDecode(row.value) as T?;
  }

  Stream<T?> watch<T>(String key) {
    return (_db.select(_db.settings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : jsonDecode(row.value) as T?);
  }
}

/// 설정 키
abstract final class SettingKeys {
  /// bool — 금액 가림(●●●) 상태
  static const maskAmounts = 'mask_amounts';
}
