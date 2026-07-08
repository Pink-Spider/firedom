import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/ym.dart';
import '../engine/engine.dart';
import 'db/database.dart';
import 'repositories/plan_repository.dart';

/// 앱 기동 준비: 레거시(SharedPreferences) 활성 계획을 plans 테이블로
/// 이관하고, 활성 계획 존재 여부를 반환한다 (라우터 시작 위치 결정용).
Future<bool> bootstrapApp(AppDatabase db, SharedPreferences prefs) async {
  const legacyKey = 'active_plan_v0';
  final repository = PlanRepository(db);
  var active = await repository.getActivePlan();

  final legacy = prefs.getString(legacyKey);
  if (legacy != null) {
    if (active == null) {
      final map = jsonDecode(legacy) as Map<String, dynamic>;
      final npsAmount = map['npsMonthlyAmount'] as int?;
      final input = PlanInput(
        age0: map['age0'] as int,
        currentAssets: map['currentAssets'] as int,
        monthlySaving: map['monthlySaving'] as int,
        realReturnBp: map['realReturnBp'] as int,
        monthlySpendRetire: map['monthlySpendRetire'] as int,
        swrBp: map['swrBp'] as int? ?? 400,
        lifeExpectancy: map['lifeExpectancy'] as int? ?? 90,
        volatilityBp: map['volatilityBp'] as int? ?? 1200,
        nps: npsAmount == null
            ? null
            : NpsInput(
                monthlyAmount: npsAmount,
                startAge: map['npsStartAge'] as int? ?? 65,
              ),
      );
      final ym = nowYm();
      active = await repository.createPlan(
        input: input,
        birthYm: birthYmFromAge(input.age0, ym),
        startedYm: ym,
      );
    }
    await prefs.remove(legacyKey);
  }
  return active != null;
}
