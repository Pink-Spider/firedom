import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/ym.dart';
import 'db/database.dart';
import 'plan_input_json.dart';
import 'repositories/plan_repository.dart';
import 'repositories/settings_store.dart';

/// 앱 기동 준비: 레거시(SharedPreferences) 활성 계획을 plans 테이블로
/// 이관하고, 라우터 시작 위치·앱 잠금 결정에 필요한 상태를 반환한다.
Future<({bool hasActivePlan, bool biometricLockEnabled})> bootstrapApp(
    AppDatabase db, SharedPreferences prefs) async {
  const legacyKey = 'active_plan_v0';
  final repository = PlanRepository(db);
  var active = await repository.getActivePlan();

  final legacy = prefs.getString(legacyKey);
  if (legacy != null) {
    if (active == null) {
      final input =
          planInputFromJson(jsonDecode(legacy) as Map<String, dynamic>);
      final ym = nowYm();
      active = await repository.createPlan(
        input: input,
        birthYm: birthYmFromAge(input.age0, ym),
        startedYm: ym,
      );
    }
    await prefs.remove(legacyKey);
  }

  final biometricLockEnabled =
      await SettingsStore(db).get<bool>(SettingKeys.biometricLock) ?? false;

  return (
    hasActivePlan: active != null,
    biometricLockEnabled: biometricLockEnabled,
  );
}
