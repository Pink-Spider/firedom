/// 연월(yyyymm 정수) 유틸 — 엔진명세 B0: 연월은 INTEGER yyyymm (예: 202607)
library;

int ymOf(DateTime date) => date.year * 100 + date.month;

int nowYm() => ymOf(DateTime.now());

int ymAddMonths(int ym, int months) {
  final total = (ym ~/ 100) * 12 + (ym % 100 - 1) + months;
  return (total ~/ 12) * 100 + (total % 12 + 1);
}

/// a → b까지 개월 수 (b가 미래면 양수)
int ymDiffMonths(int a, int b) {
  return ((b ~/ 100) * 12 + b % 100) - ((a ~/ 100) * 12 + a % 100);
}

const _enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 연월 표시 — ko "2026년 7월" / ja "2026年7月" / 그 외 "Jul 2026".
/// intl 날짜 심볼 초기화에 의존하지 않도록 직접 조립한다 (순수 Dart 테스트 호환)
String formatYm(int ym, {String languageCode = 'ko'}) {
  final year = ym ~/ 100;
  final month = ym % 100;
  switch (languageCode) {
    case 'ko':
      return '$year년 $month월';
    case 'ja':
      return '$year年$month月';
    default:
      return '${_enMonths[(month - 1).clamp(0, 11)]} $year';
  }
}

/// 생년월 기준 만 나이 (월 단위 절사)
int ageFromBirthYm(int birthYm, int atYm) => ymDiffMonths(birthYm, atYm) ~/ 12;

/// 나이 → 근사 생년월 (온보딩은 만 나이만 받으므로 현재 월 기준 환산)
int birthYmFromAge(int age, int atYm) => ymAddMonths(atYm, -age * 12);
