import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// 포트폴리오 모드 (엔진명세 A11) — G8 골든 + 검증 규약
///
/// G8 기대값은 `docs/자산군_프리셋_근거.md` §1의 프리셋과 균형형 구성에서
/// 산출: r_port = round(Σwᵢrᵢ/10000) = 380bp, σ_port = 1610bp (정확 일치).
void main() {
  group('엔진명세 A11 G8 골든 (정확 일치)', () {
    test('G8: 균형형 구성 — r_port=380bp, σ_port=1610bp', () {
      final p = balancedExamplePortfolio();
      expect(p.portfolioReturnBp, 380);
      expect(p.portfolioVolatilityBp, 1610);
    });

    test('G8: 축약 동치성 — 포트폴리오 모드 ≡ 단순 모드 380bp', () {
      const base = PlanInput(
        age0: 35,
        currentAssets: 100000000,
        monthlySaving: 2000000,
        realReturnBp: 400, // applyTo가 덮어쓴다
        monthlySpendRetire: 3000000,
        swrBp: 400,
      );
      final viaPortfolio = solvePlan(balancedExamplePortfolio().applyTo(base));
      final viaSimple = solvePlan(
        base.copyWith(realReturnBp: 380, volatilityBp: 1610),
      );
      expect(viaPortfolio.fireNumber, viaSimple.fireNumber);
      expect(viaPortfolio.monthsToFire, viaSimple.monthsToFire);
      expect(viaPortfolio.assetsByMonth, viaSimple.assetsByMonth);
    });
  });

  group('가중 축약 규약 (A11 1단계)', () {
    test('반올림: Σ이 10000으로 나눠떨어지지 않아도 round', () {
      // 3333×100 + 3333×200 + 3334×300 = 333,300 + 666,600 + 1,000,200
      // = 2,000,100 → /10000 = 200.01 → 200
      final p = PortfolioInput(holdings: const [
        PortfolioHolding(
            assetKey: 'a', weightBp: 3333, realReturnBp: 100, volatilityBp: 0),
        PortfolioHolding(
            assetKey: 'b', weightBp: 3333, realReturnBp: 200, volatilityBp: 0),
        PortfolioHolding(
            assetKey: 'c', weightBp: 3334, realReturnBp: 300, volatilityBp: 0),
      ]);
      expect(p.portfolioReturnBp, 200);
    });

    test('단일 자산 10000 허용 — 프리셋 값 그대로 축약', () {
      final p = PortfolioInput(holdings: [
        PortfolioHolding.fromPreset(PortfolioAsset.usSp500, weightBp: 10000),
      ]);
      expect(p.portfolioReturnBp, PortfolioAsset.usSp500.realReturnBp);
      expect(p.portfolioVolatilityBp, PortfolioAsset.usSp500.volatilityBp);
    });

    test('weightBp=0 항목은 무시된다', () {
      final p = PortfolioInput(holdings: [
        PortfolioHolding.fromPreset(PortfolioAsset.usSp500, weightBp: 10000),
        PortfolioHolding.fromPreset(PortfolioAsset.gold, weightBp: 0),
      ]);
      expect(p.holdings.length, 1);
      expect(p.portfolioReturnBp, PortfolioAsset.usSp500.realReturnBp);
    });

    test('합계 ≠ 10000이면 거부 (엔진 진입 전)', () {
      expect(
        () => PortfolioInput(holdings: [
          PortfolioHolding.fromPreset(PortfolioAsset.usSp500, weightBp: 9000),
        ]),
        throwsArgumentError,
      );
      expect(
        () => PortfolioInput(holdings: [
          PortfolioHolding.fromPreset(PortfolioAsset.usSp500, weightBp: 10001),
        ]),
        throwsArgumentError,
      );
    });

    test('음수 비중 거부', () {
      expect(
        () => PortfolioInput(holdings: const [
          PortfolioHolding(
              assetKey: 'a',
              weightBp: 11000,
              realReturnBp: 100,
              volatilityBp: 100),
          PortfolioHolding(
              assetKey: 'b',
              weightBp: -1000,
              realReturnBp: 100,
              volatilityBp: 100),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('자산군 프리셋 (근거 문서 §1)', () {
    test('13개 자산군, assetKey 유일', () {
      expect(PortfolioAsset.values.length, 13);
      final keys = PortfolioAsset.values.map((a) => a.key).toSet();
      expect(keys.length, 13);
    });

    test('검증(✅) 자산군: S&P500·선진국/신흥국·미국채·달러·금', () {
      final verified = PortfolioAsset.values
          .where((a) => a.verified)
          .map((a) => a.key)
          .toSet();
      expect(verified, {
        'us_sp500',
        'global_dm_em',
        'us_treasury',
        'usd_cash',
        'gold',
      });
    });

    test('모든 프리셋에 출처 문자열 존재 (가정 보기 노출용)', () {
      for (final a in PortfolioAsset.values) {
        expect(a.source, isNotEmpty, reason: a.key);
      }
    });

    test('예시 구성 4종: 비중 합계 10000 보장 (생성 시 검증 통과)', () {
      for (final example in PortfolioExample.values) {
        expect(example.build, returnsNormally, reason: example.name);
      }
    });
  });
}
