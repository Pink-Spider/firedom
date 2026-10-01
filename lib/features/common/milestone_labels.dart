/// 마일스톤 키 → 표시 문구 (언어·통화별)
library;

import '../../core/currency.dart';
import '../../core/money_format.dart';
import '../../engine/milestones.dart';
import '../../l10n/l10n.dart';

String milestoneLabel(AppLocalizations l10n, Currency currency, String key) {
  final tier = netWorthMilestoneKeys.indexOf(key);
  if (tier >= 0) {
    return l10n.msNetWorth(_tierAmount(l10n, currency, currency.netWorthTiers[tier]));
  }
  return switch (key) {
    'fire_25pct' => l10n.msFire25,
    'fire_50pct' => l10n.msFire50,
    'fire_75pct' => l10n.msFire75,
    'fire_100pct' => l10n.msFire100,
    'streak_3mo' => l10n.msStreak3,
    'streak_6mo' => l10n.msStreak6,
    'streak_12mo' => l10n.msStreak12,
    _ => l10n.msFallback,
  };
}

/// 축약 금액. 한국어+원화에서 억 단위 정수는 기존 문구대로 단위어를 생략한다
/// ("순자산 1억 돌파!" — "1억원 돌파"가 아니라)
String _tierAmount(AppLocalizations l10n, Currency currency, int amount) {
  const eok = 100000000;
  if (l10n.localeName == 'ko' &&
      currency == Currency.krw &&
      amount >= eok &&
      amount % eok == 0) {
    return formatKoreanMoney(amount);
  }
  return MoneyFormat(currency, l10n.localeName).compact(amount);
}
