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

/// y축 라벨 칸 너비. 일본어 "6,000万"처럼 긴 라벨이 두 줄로 접히지 않을 만큼 둔다
/// (44로는 접혔다). 차트 폭은 그만큼 줄지만 라벨이 깨지는 것보다 낫다.
const chartAxisLabelWidth = 68.0;

/// y축 눈금 라벨 — 축 값 × 단위를 통화·언어에 맞춰 축약 ("1억" / "$100K" / "1億")
/// CJK는 단위어를 빼 한 줄에 들어가게 한다 ([MoneyFormat.axis]).
/// 가림 모드에서는 빈 문자열 (축 눈금 자체를 숨긴다)
String chartAmountLabel(MoneyFormat money, double axisValue, int unit) =>
    money.masked ? '' : money.axis((axisValue * unit).round());
