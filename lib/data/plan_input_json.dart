import '../engine/engine.dart';

/// PlanInput ↔ JSON (시나리오 저장·레거시 이관용)
Map<String, dynamic> planInputToJson(PlanInput input) {
  return {
    'age0': input.age0,
    'currentAssets': input.currentAssets,
    'monthlySaving': input.monthlySaving,
    'realReturnBp': input.realReturnBp,
    'monthlySpendRetire': input.monthlySpendRetire,
    'swrBp': input.swrBp,
    'lifeExpectancy': input.lifeExpectancy,
    'volatilityBp': input.volatilityBp,
    if (input.nps != null) 'npsMonthlyAmount': input.nps!.monthlyAmount,
    if (input.nps != null) 'npsStartAge': input.nps!.startAge,
  };
}

PlanInput planInputFromJson(Map<String, dynamic> map) {
  final npsAmount = map['npsMonthlyAmount'] as int?;
  return PlanInput(
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
}
