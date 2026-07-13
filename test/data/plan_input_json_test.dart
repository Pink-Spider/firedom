import 'package:firedom/data/plan_input_json.dart';
import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scenarios.params_json 직렬화 (B1)', () {
    test('PlanInput 라운드트립', () {
      const input = PlanInput(
        age0: 35,
        currentAssets: 100000000,
        monthlySaving: 2000000,
        realReturnBp: 400,
        monthlySpendRetire: 3000000,
        nps: NpsInput(monthlyAmount: 900000, startAge: 65),
      );
      final restored = planInputFromJson(planInputToJson(input));
      expect(restored.age0, input.age0);
      expect(restored.realReturnBp, input.realReturnBp);
      expect(restored.nps!.monthlyAmount, 900000);
    });

    test('portfolio 필드 라운드트립 — 축약 결과 보존', () {
      final portfolio = balancedExamplePortfolio();
      final restored = portfolioFromJson(portfolioToJson(portfolio));
      expect(restored.holdings.length, portfolio.holdings.length);
      expect(restored.portfolioReturnBp, 380); // G8
      expect(restored.portfolioVolatilityBp, 1610);
      expect(
        restored.holdings.map((h) => h.assetKey),
        portfolio.holdings.map((h) => h.assetKey),
      );
    });

    test('손상 데이터(비중 합계 ≠ 10000)는 복원 시 ArgumentError', () {
      final bad = {
        'holdings': [
          {
            'assetKey': 'us_sp500',
            'weightBp': 9000,
            'realReturnBp': 650,
            'volatilityBp': 2000,
          },
        ],
      };
      expect(() => portfolioFromJson(bad), throwsArgumentError);
    });
  });
}
