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

/// PortfolioInput → JSON — scenarios.params_json의 선택적 `portfolio` 필드
/// (엔진명세 B1). v1.1에서 놀이터(시나리오) 전용, plans에는 저장하지 않는다.
Map<String, dynamic> portfolioToJson(PortfolioInput portfolio) {
  return {
    'holdings': [
      for (final h in portfolio.holdings)
        {
          'assetKey': h.assetKey,
          'weightBp': h.weightBp,
          'realReturnBp': h.realReturnBp,
          'volatilityBp': h.volatilityBp,
        },
    ],
  };
}

/// JSON → PortfolioInput. 비중 합계 검증(A11)은 PortfolioInput 생성자가
/// 수행하므로, 손상된 데이터는 여기서 [ArgumentError]로 드러난다.
PortfolioInput portfolioFromJson(Map<String, dynamic> map) {
  final holdings = (map['holdings'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map((h) => PortfolioHolding(
            assetKey: h['assetKey'] as String,
            weightBp: h['weightBp'] as int,
            realReturnBp: h['realReturnBp'] as int,
            volatilityBp: h['volatilityBp'] as int,
          ))
      .toList();
  return PortfolioInput(holdings: holdings);
}
