import '../common/money.dart';

/// 자산 궤도 차트의 y축 한 단위 (통화 최소 단위).
///
/// KRW·JPY는 1억(億), USD는 10만 달러(=1,000만 센트)로 두어 축 값이
/// 사람에게 자연스러운 정수 눈금이 되게 한다. 라벨은 [chartAmountLabel]로 그린다.
int chartAmountUnit(Currency currency) => switch (currency) {
      Currency.krw => 100000000,
      Currency.jpy => 100000000,
      Currency.usd => 10000000,
    };

/// y축 눈금 라벨 — 축 값 × 단위를 통화·언어에 맞춰 축약 ("1억원" / "$100K" / "1億円")
/// 가림 모드에서는 빈 문자열 (축 눈금 자체를 숨긴다)
String chartAmountLabel(MoneyFormat money, double axisValue, int unit) =>
    money.masked ? '' : money.compact((axisValue * unit).round());
