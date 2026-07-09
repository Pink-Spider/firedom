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

  /// bool — 월간 기록 리마인더 사용
  static const reminderEnabled = 'reminder.enabled';

  /// int — 리마인더 일자 (0 = 매월 말일)
  static const reminderDay = 'reminder.day';

  /// int — 리마인더 시각 (시)
  static const reminderHour = 'reminder.hour';

  /// int — 리마인더 시각 (분)
  static const reminderMinute = 'reminder.minute';

  /// bool — 생체인증 앱 잠금
  static const biometricLock = 'biometric_lock';

  /// `Map<String, int>` — 목표 자산 배분 (자산군 → %)
  static const targetAllocation = 'target_allocation';
}
