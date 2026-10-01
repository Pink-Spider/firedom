/// 통화 (전역 규약 확장).
///
/// 금액은 여전히 **정수**로 저장하되, 단위는 '원'이 아니라 **통화의 최소 단위**다.
/// KRW·JPY는 소수점이 없어 최소 단위 = 1원/1엔이고, USD는 센트다.
/// 기존 한국 사용자의 원화 데이터는 그대로 유효하다 (KRW 최소 단위 = 원).
///
/// 엔진은 통화를 모른다 — 정수 금액에 bp 수익률을 곱할 뿐이다. 통화는 표시·입력·
/// 슬라이더 범위·마일스톤 기준처럼 UI가 "사람에게 자연스러운 크기"를 정할 때만 쓴다.
library;

enum Currency {
  krw(
    code: 'KRW',
    decimals: 0,
    symbol: '₩',
    largeUnit: 10000,
    monthlyStep: 100000,
    netWorthTiers: [
      50000000,
      100000000,
      300000000,
      500000000,
      1000000000,
    ],
  ),
  usd(
    code: 'USD',
    decimals: 2,
    symbol: r'$',
    largeUnit: null,
    monthlyStep: 10000, // $100
    netWorthTiers: [
      5000000, // $50k
      10000000, // $100k
      25000000, // $250k
      50000000, // $500k
      100000000, // $1M
    ],
  ),
  jpy(
    code: 'JPY',
    decimals: 0,
    symbol: '¥',
    largeUnit: 10000,
    monthlyStep: 10000,
    netWorthTiers: [
      5000000,
      10000000,
      30000000,
      50000000,
      100000000,
    ],
  );

  /// ISO 4217 코드 — settings 테이블에 저장되는 값
  final String code;

  /// 최소 단위 자릿수 (USD 2 → 센트)
  final int decimals;

  final String symbol;

  /// 입력 보조 단위 (만원·万円). 없으면 주 단위만 입력받는다
  final int? largeUnit;

  /// 월 단위 금액 슬라이더의 한 칸 (최소 단위). 저축·생활비 슬라이더 범위의 기준
  final int monthlyStep;

  /// 순자산 마일스톤 기준 5단계 (최소 단위, 오름차순).
  /// 키는 통화와 무관하게 `net_worth_tier_1..5`의 기존 키(`net_worth_50m` 등)를 재사용한다
  final List<int> netWorthTiers;

  const Currency({
    required this.code,
    required this.decimals,
    required this.symbol,
    required this.largeUnit,
    required this.monthlyStep,
    required this.netWorthTiers,
  });

  /// 주 단위 1 = 최소 단위 몇 개 (USD 100, KRW·JPY 1)
  int get minorPerMajor => decimals == 0 ? 1 : (decimals == 1 ? 10 : 100);

  /// 설정에 값이 없을 때 — 기존 설치는 전부 원화였다
  static const fallback = Currency.krw;

  static Currency fromCode(String? code) {
    for (final c in Currency.values) {
      if (c.code == code) return c;
    }
    return fallback;
  }

  /// 기기 언어에 따른 기본값 (온보딩 첫 화면 초기 선택)
  static Currency defaultForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return Currency.krw;
      case 'ja':
        return Currency.jpy;
      default:
        return Currency.usd;
    }
  }
}
