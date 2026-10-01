import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'currency.dart';

final NumberFormat _thousands = NumberFormat('#,###');

/// 1,234,567 형태 콤마 표기
String formatWithComma(int value) => _thousands.format(value);

/// 한국식 금액 축약: 9억 / 1억 2,000만 / 300만 / 5,000
String formatKoreanMoney(int won) => _formatCjkCompact(won, eok: '억', man: '만');

/// 일본식 축약: 9億 / 1億2,000万 / 300万 (한국식과 같은 4자리 체계, 띄어쓰기 없음)
String formatJapaneseMoney(int yen) =>
    _formatCjkCompact(yen, eok: '億', man: '万', separator: '');

String _formatCjkCompact(
  int value, {
  required String eok,
  required String man,
  String separator = ' ',
}) {
  if (value == 0) return '0';
  final sign = value < 0 ? '−' : '';
  final abs = value.abs();
  final e = abs ~/ 100000000;
  final m = (abs % 100000000) ~/ 10000;
  final rest = abs % 10000;
  final parts = <String>[
    if (e > 0) '${_thousands.format(e)}$eok',
    if (m > 0) '${_thousands.format(m)}$man',
    if (rest > 0) _thousands.format(rest),
  ];
  return '$sign${parts.join(separator)}';
}

/// 콤마 포함 문자열 → 정수 (숫자 없으면 null)
int? parseAmount(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// 통화·언어별 금액 표기.
///
/// 금액 인자는 항상 **최소 단위 정수**([Currency] 참조). 표기 규칙:
/// - 한국어·일본어 UI: 억/만(億/万) 4자리 축약 + 통화 단위어 ("1억 2,000만원", "120万円", "35만 달러")
/// - 그 외(영어) UI: ISO 통화 기호 접두 ("$1.2M", "₩120M" / 전체 "$1,234,567")
/// - USD 센트는 전체 표기에서 0이 아닐 때만 보인다 ("$12.50")
class MoneyFormat {
  final Currency currency;

  /// 'ko' | 'en' | 'ja'
  final String languageCode;

  /// 금액 가림(●●●) 설정. true면 [full]/[compact]가 금액 대신 가림 문자를 돌려준다.
  /// 입력 필드용 접두·접미어([inputPrefix] 등)는 가리지 않는다
  final bool masked;

  /// 가림 표시 — 번역하지 않는다 (arb의 commonMasked와 동일)
  static const maskedText = '●●●';

  const MoneyFormat(this.currency, this.languageCode, {this.masked = false});

  bool get _cjk => languageCode == 'ko' || languageCode == 'ja';

  /// 통화 단위어 (CJK UI에서 숫자 뒤에 붙는 말)
  String get unitWord {
    switch (languageCode) {
      case 'ko':
        return switch (currency) {
          Currency.krw => '원',
          Currency.usd => '달러',
          Currency.jpy => '엔',
        };
      case 'ja':
        return switch (currency) {
          Currency.krw => 'ウォン',
          Currency.usd => 'ドル',
          Currency.jpy => '円',
        };
      default:
        return currency.symbol;
    }
  }

  /// 입력 필드 접두 기호 (영어 UI: "$", "₩", "¥"). CJK UI는 접미어를 쓴다
  String get inputPrefix => _cjk ? '' : currency.symbol;

  /// 입력 필드 접미어 (CJK UI: "원"/"円"/"달러"). 영어 UI는 접두 기호를 쓴다
  String get inputSuffix => _cjk ? unitWord : '';

  /// 입력 보조 단위(만원/万円)를 쓸 수 있는가 — CJK UI + 4자리 축약 통화일 때만
  bool get hasLargeInputUnit => _cjk && currency.largeUnit != null;

  /// 보조 단위 라벨 ("만원", "万円", "만 달러")
  String get largeUnitWord {
    final prefix = languageCode == 'ja' ? '万' : '만';
    return switch ((languageCode, currency)) {
      ('ko', Currency.krw) => '만원',
      ('ja', Currency.jpy) => '万円',
      _ => '$prefix $unitWord',
    };
  }

  /// 전체 표기 — "1,234,567원" / "$1,234,567" / "$12.50" / "¥1,234,567"
  String full(int minor) {
    if (masked) return maskedText;
    final sign = minor < 0 ? '−' : '';
    final abs = minor.abs();
    final major = abs ~/ currency.minorPerMajor;
    final cents = abs % currency.minorPerMajor;
    final centsText = cents == 0
        ? ''
        : '.${cents.toString().padLeft(currency.decimals, '0')}';
    final number = '${_thousands.format(major)}$centsText';
    if (_cjk) return '$sign$number$unitWord';
    return '$sign${currency.symbol}$number';
  }

  /// 축약 표기 — "1억 2,000만원" / "120万円" / "$1.23M" / "₩120M".
  /// 센트는 버린다 (축약 표기는 크기 감각용)
  String compact(int minor) {
    if (masked) return maskedText;
    final sign = minor < 0 ? '−' : '';
    final major = minor.abs() ~/ currency.minorPerMajor;
    if (_cjk) {
      final number = languageCode == 'ja'
          ? formatJapaneseMoney(major)
          : formatKoreanMoney(major);
      return '$sign$number$unitWord';
    }
    if (major < 10000) return '$sign${currency.symbol}${_thousands.format(major)}';
    final text = NumberFormat.compactSimpleCurrency(
      locale: 'en_US',
      name: currency.code,
      decimalDigits: 1,
    ).format(major);
    // "$1.0M" → "$1M"
    return '$sign${text.replaceAll(RegExp(r'\.0(?=[KMBT]$)'), '')}';
  }
}

/// 숫자 입력에 천 단위 콤마를 실시간 적용 (PRD S1)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final parsed = int.tryParse(digits);
    if (parsed == null) return oldValue;
    final formatted = _thousands.format(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
