/// 포트폴리오 모드 (엔진명세 A11, S4-2) — 가중 축약 프리프로세서.
///
/// 자산군별 비중을 (실질수익률, 변동성) 쌍으로 축약해 [PlanInput]에 넣는
/// 계층이다. 엔진 본체(A2~A6)는 변경하지 않는다.
///
/// 프리셋 근거·출처: `docs/자산군_프리셋_근거.md`
/// (실질·연 기하평균 기준. 해외자산은 USD 기준 — USD/KRW 환변동 미반영)
library;

import 'models.dart';

/// 자산군 프리셋 (엔진명세 A11 표).
///
/// [verified] = 1차 출처 3표 교차 검증 통과. false는 잠정치 — 출시 전 확정
/// 필요(PRD §11), UI에서 "참고치" 라벨을 붙인다.
/// [source]는 "가정 보기"에 그대로 노출하는 출처 문자열.
enum PortfolioAsset {
  usSp500(
    key: 'us_sp500',
    label: 'S&P500',
    realReturnBp: 650,
    volatilityBp: 2000,
    verified: true,
    source: 'Damodaran 1928–2025 · UBS/DMS 1900–2024 · Siegel 1802–2023',
  ),
  usNasdaq100(
    key: 'us_nasdaq100',
    label: '나스닥100',
    realReturnBp: 750,
    volatilityBp: 2400,
    verified: false,
    source: '잠정 — S&P500 검증치 + 성장주 스프레드 가정',
  ),
  usDow(
    key: 'us_dow',
    label: '다우존스',
    realReturnBp: 600,
    volatilityBp: 1900,
    verified: false,
    source: '잠정 — S&P500 근사',
  ),
  krEquity(
    key: 'kr_equity',
    label: '국내주식',
    realReturnBp: 400,
    volatilityBp: 2200,
    verified: false,
    source: '잠정 — 변동성은 DMS 단일국 주식 실질 SD 계층(2,000~2,300bp)',
  ),
  globalDmEm(
    key: 'global_dm_em',
    label: '선진국·신흥국',
    realReturnBp: 450,
    volatilityBp: 1800,
    verified: true,
    source: 'DMS World 1900–2010 실질 5.5% · MSCI World/EM 팩트시트 2026-06',
  ),
  krTreasury(
    key: 'kr_treasury',
    label: '국고채',
    realReturnBp: 100,
    volatilityBp: 800,
    verified: false,
    source: '잠정 — DMS 국가평균(60~90bp)~미국(150bp) 보수 구간',
  ),
  usTreasury(
    key: 'us_treasury',
    label: '미국채',
    realReturnBp: 150,
    volatilityBp: 900,
    verified: true,
    source: 'Damodaran 10년물 1928–2025 실질 1.45% (USD 기준, 환노출 별도)',
  ),
  usdCash(
    key: 'usd_cash',
    label: '달러(외환)',
    realReturnBp: 50,
    volatilityBp: 300,
    verified: true,
    source: '3개월 T-Bill 프록시, Damodaran·DMS (USD 기준, 환변동 미반영)',
  ),
  krwDeposit(
    key: 'krw_deposit',
    label: '원화 예금',
    realReturnBp: 50,
    volatilityBp: 100,
    verified: false,
    source: '잠정 — 실질 예금금리 보수 가정, 한국은행 통계 후속 소싱',
  ),
  gold(
    key: 'gold',
    label: '금',
    realReturnBp: 200,
    volatilityBp: 2500,
    verified: true,
    source: 'Damodaran 1928– 실질 2.5% · 자유변동기 1971– 4.9% (기간 민감)',
  ),
  silver(
    key: 'silver',
    label: '은',
    realReturnBp: 100,
    volatilityBp: 3000,
    verified: false,
    source: '잠정 — 금 대비 저수익·고변동 가정',
  ),
  commodities(
    key: 'commodities',
    label: '원자재',
    realReturnBp: 100,
    volatilityBp: 2000,
    verified: false,
    source: '잠정 — 후속 소싱 (BCOM)',
  ),
  reits(
    key: 'reits',
    label: '리츠',
    realReturnBp: 350,
    volatilityBp: 2000,
    verified: false,
    source: '잠정 — 후속 소싱 (FTSE EPRA Nareit)',
  );

  final String key;
  final String label;
  final int realReturnBp;
  final int volatilityBp;
  final bool verified;
  final String source;

  const PortfolioAsset({
    required this.key,
    required this.label,
    required this.realReturnBp,
    required this.volatilityBp,
    required this.verified,
    required this.source,
  });
}

/// 포트폴리오 보유 항목 (엔진명세 A11 입력 모델).
///
/// [realReturnBp]/[volatilityBp]는 프리셋 기본값에서 시작하되 유저가 수정
/// 가능한 '가정'이다 (앱의 전망이 아님 — PRD S4-2).
class PortfolioHolding {
  /// 자산군 키 ([PortfolioAsset.key])
  final String assetKey;

  /// 비중 (bp, 전체 합계 10000 필수)
  final int weightBp;

  /// 연 실질수익률 가정 (bp)
  final int realReturnBp;

  /// 연 변동성 가정 (bp)
  final int volatilityBp;

  const PortfolioHolding({
    required this.assetKey,
    required this.weightBp,
    required this.realReturnBp,
    required this.volatilityBp,
  });

  /// 프리셋 기본 가정으로 보유 항목 생성.
  PortfolioHolding.fromPreset(PortfolioAsset asset, {required int weightBp})
      : this(
          assetKey: asset.key,
          weightBp: weightBp,
          realReturnBp: asset.realReturnBp,
          volatilityBp: asset.volatilityBp,
        );
}

/// 포트폴리오 입력 — 검증과 가중 축약(1단계)을 담당한다.
///
/// 규약(A11): 비중 합계가 10000(=100%)이 아니면 엔진 진입 전 거부.
/// 자동 정규화 제안은 UI 레이어 책임. weightBp = 0 항목은 무시.
/// 단일 자산 10000 허용.
class PortfolioInput {
  /// 비중 0 항목을 제거한 보유 목록
  final List<PortfolioHolding> holdings;

  PortfolioInput({required List<PortfolioHolding> holdings})
      : holdings = List.unmodifiable(
          holdings.where((h) => h.weightBp != 0),
        ) {
    for (final h in this.holdings) {
      if (h.weightBp < 0) {
        throw ArgumentError.value(
          h.weightBp, 'weightBp', '음수 비중은 허용하지 않는다 (${h.assetKey})');
      }
    }
    final total = this.holdings.fold(0, (sum, h) => sum + h.weightBp);
    if (total != 10000) {
      throw ArgumentError.value(
        total, 'holdings', '비중 합계는 10000bp(100%)여야 한다 (엔진명세 A11)');
    }
  }

  /// 가중 평균 실질수익률 (bp) — r_port = round(Σ(wᵢ×rᵢ)/10000)
  int get portfolioReturnBp => _weighted((h) => h.realReturnBp);

  /// 가중 평균 변동성 (bp) — 상관계수 1 가정의 보수적 상한(간이 추정).
  /// 2단계(v2) 상관행렬 몬테카를로에서 대체된다.
  int get portfolioVolatilityBp => _weighted((h) => h.volatilityBp);

  int _weighted(int Function(PortfolioHolding) f) {
    final sum = holdings.fold(0, (acc, h) => acc + h.weightBp * f(h));
    return (sum / 10000).round();
  }

  /// 축약 결과를 [base]에 투입한 [PlanInput] 반환 — 이후 A2~A6 그대로.
  PlanInput applyTo(PlanInput base) => base.copyWith(
        realReturnBp: portfolioReturnBp,
        volatilityBp: portfolioVolatilityBp,
      );
}

/// 예시 구성 (엔진명세 A11 표).
///
/// UI 명명은 "예시 구성" — "추천" 표현 금지 (PRD S4-2, 제품 원칙 4).
/// 특정 구성을 권하지 않으며, 유저 편집의 출발점일 뿐이다.
enum PortfolioExample {
  stable('안정형'),
  balanced('균형형'),
  growth('성장형'),
  allWeather('올웨더');

  final String label;

  const PortfolioExample(this.label);

  /// 프리셋 기본 가정으로 구성한 [PortfolioInput] (비중 합계 10000 보장)
  PortfolioInput build() {
    List<PortfolioHolding> h(List<(PortfolioAsset, int)> entries) => [
          for (final (asset, weightBp) in entries)
            PortfolioHolding.fromPreset(asset, weightBp: weightBp),
        ];
    switch (this) {
      case PortfolioExample.stable:
        return PortfolioInput(holdings: h([
          (PortfolioAsset.usTreasury, 3000),
          (PortfolioAsset.krTreasury, 2500),
          (PortfolioAsset.usSp500, 1500),
          (PortfolioAsset.krwDeposit, 1500),
          (PortfolioAsset.usdCash, 1000),
          (PortfolioAsset.gold, 500),
        ]));
      case PortfolioExample.balanced:
        return PortfolioInput(holdings: h([
          (PortfolioAsset.usSp500, 2500),
          (PortfolioAsset.usNasdaq100, 1500),
          (PortfolioAsset.krEquity, 1000),
          (PortfolioAsset.usTreasury, 2000),
          (PortfolioAsset.krTreasury, 1000),
          (PortfolioAsset.gold, 1000),
          (PortfolioAsset.usdCash, 500),
          (PortfolioAsset.krwDeposit, 500),
        ]));
      case PortfolioExample.growth:
        return PortfolioInput(holdings: h([
          (PortfolioAsset.usSp500, 3500),
          (PortfolioAsset.usNasdaq100, 2500),
          (PortfolioAsset.globalDmEm, 1500),
          (PortfolioAsset.krEquity, 1000),
          (PortfolioAsset.usTreasury, 1000),
          (PortfolioAsset.gold, 500),
        ]));
      case PortfolioExample.allWeather:
        return PortfolioInput(holdings: h([
          (PortfolioAsset.usSp500, 3000),
          (PortfolioAsset.usTreasury, 4000),
          (PortfolioAsset.krTreasury, 1500),
          (PortfolioAsset.gold, 750),
          (PortfolioAsset.commodities, 750),
        ]));
    }
  }
}

/// 균형형 예시 구성 — G8 골든 테스트 기준 (r_port=380bp, σ_port=1610bp)
PortfolioInput balancedExamplePortfolio() =>
    PortfolioExample.balanced.build();
