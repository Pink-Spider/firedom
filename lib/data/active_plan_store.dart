import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/engine.dart';
import 'prefs.dart';

/// 활성 계획 임시 저장소.
///
/// TODO(data): Drift `plans` 테이블(엔진명세 B1)로 대체 예정.
/// 리비전 이력·UUID PK 등 스키마 규약은 그 시점에 적용한다.
class ActivePlanStore {
  static const _key = 'active_plan_v0';

  final SharedPreferences _prefs;

  ActivePlanStore(this._prefs);

  bool get hasPlan => _prefs.containsKey(_key);

  Future<void> save(PlanInput plan) async {
    await _prefs.setString(_key, jsonEncode({
      'age0': plan.age0,
      'currentAssets': plan.currentAssets,
      'monthlySaving': plan.monthlySaving,
      'realReturnBp': plan.realReturnBp,
      'monthlySpendRetire': plan.monthlySpendRetire,
      'swrBp': plan.swrBp,
      'lifeExpectancy': plan.lifeExpectancy,
      'volatilityBp': plan.volatilityBp,
      if (plan.nps != null) 'npsMonthlyAmount': plan.nps!.monthlyAmount,
      if (plan.nps != null) 'npsStartAge': plan.nps!.startAge,
    }));
  }

  PlanInput? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final npsAmount = map['npsMonthlyAmount'] as int?;
    return PlanInput(
      age0: map['age0'] as int,
      currentAssets: map['currentAssets'] as int,
      monthlySaving: map['monthlySaving'] as int,
      realReturnBp: map['realReturnBp'] as int,
      monthlySpendRetire: map['monthlySpendRetire'] as int,
      swrBp: map['swrBp'] as int,
      lifeExpectancy: map['lifeExpectancy'] as int,
      volatilityBp: map['volatilityBp'] as int,
      nps: npsAmount == null
          ? null
          : NpsInput(
              monthlyAmount: npsAmount,
              startAge: map['npsStartAge'] as int,
            ),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}

final activePlanStoreProvider = Provider<ActivePlanStore>(
  (ref) => ActivePlanStore(ref.watch(sharedPreferencesProvider)),
);

/// 현재 활성 계획. 저장/삭제 후에는 invalidate 필요.
final activePlanProvider = Provider<PlanInput?>(
  (ref) => ref.watch(activePlanStoreProvider).load(),
);
