/// 엔진 포트폴리오 프리셋([PortfolioAsset]·[PortfolioExample])의 표시 문구.
///
/// 엔진(`lib/engine/`)은 순수 Dart라 l10n에 의존할 수 없으므로 UI 쪽에서
/// `key`/enum 값으로 arb 키를 고른다. ko 문구는 엔진의 `label`/`source`와
/// 글자 단위로 동일하게 유지한다 (`test/portfolio_labels_test.dart`).
library;

import '../../engine/portfolio.dart';
import '../../l10n/l10n.dart';

/// 자산군 표시 이름 (엔진 `PortfolioAsset.label`의 다국어판)
String portfolioAssetLabel(AppLocalizations l10n, PortfolioAsset asset) {
  switch (asset) {
    case PortfolioAsset.usSp500:
      return l10n.pfAssetUsSp500;
    case PortfolioAsset.usNasdaq100:
      return l10n.pfAssetUsNasdaq100;
    case PortfolioAsset.usDow:
      return l10n.pfAssetUsDow;
    case PortfolioAsset.krEquity:
      return l10n.pfAssetKrEquity;
    case PortfolioAsset.globalDmEm:
      return l10n.pfAssetGlobalDmEm;
    case PortfolioAsset.krTreasury:
      return l10n.pfAssetKrTreasury;
    case PortfolioAsset.usTreasury:
      return l10n.pfAssetUsTreasury;
    case PortfolioAsset.usdCash:
      return l10n.pfAssetUsdCash;
    case PortfolioAsset.krwDeposit:
      return l10n.pfAssetKrwDeposit;
    case PortfolioAsset.gold:
      return l10n.pfAssetGold;
    case PortfolioAsset.silver:
      return l10n.pfAssetSilver;
    case PortfolioAsset.commodities:
      return l10n.pfAssetCommodities;
    case PortfolioAsset.reits:
      return l10n.pfAssetReits;
  }
}

/// 자산군 출처 문자열 (엔진 `PortfolioAsset.source`의 다국어판 — "가정 보기")
String portfolioAssetSource(AppLocalizations l10n, PortfolioAsset asset) {
  switch (asset) {
    case PortfolioAsset.usSp500:
      return l10n.pfSourceUsSp500;
    case PortfolioAsset.usNasdaq100:
      return l10n.pfSourceUsNasdaq100;
    case PortfolioAsset.usDow:
      return l10n.pfSourceUsDow;
    case PortfolioAsset.krEquity:
      return l10n.pfSourceKrEquity;
    case PortfolioAsset.globalDmEm:
      return l10n.pfSourceGlobalDmEm;
    case PortfolioAsset.krTreasury:
      return l10n.pfSourceKrTreasury;
    case PortfolioAsset.usTreasury:
      return l10n.pfSourceUsTreasury;
    case PortfolioAsset.usdCash:
      return l10n.pfSourceUsdCash;
    case PortfolioAsset.krwDeposit:
      return l10n.pfSourceKrwDeposit;
    case PortfolioAsset.gold:
      return l10n.pfSourceGold;
    case PortfolioAsset.silver:
      return l10n.pfSourceSilver;
    case PortfolioAsset.commodities:
      return l10n.pfSourceCommodities;
    case PortfolioAsset.reits:
      return l10n.pfSourceReits;
  }
}

/// 예시 구성 이름 (엔진 `PortfolioExample.label`의 다국어판). "추천" 아님.
String portfolioExampleLabel(AppLocalizations l10n, PortfolioExample example) {
  switch (example) {
    case PortfolioExample.stable:
      return l10n.pfExampleStable;
    case PortfolioExample.balanced:
      return l10n.pfExampleBalanced;
    case PortfolioExample.growth:
      return l10n.pfExampleGrowth;
    case PortfolioExample.allWeather:
      return l10n.pfExampleAllWeather;
  }
}
