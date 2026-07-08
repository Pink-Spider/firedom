import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _thousands = NumberFormat('#,###');

/// 1,234,567 형태 콤마 표기
String formatWithComma(int value) => _thousands.format(value);

/// 한국식 금액 축약: 9억 / 1억 2,000만 / 300만 / 5,000
String formatKoreanMoney(int won) {
  if (won == 0) return '0';
  final sign = won < 0 ? '−' : '';
  final abs = won.abs();
  final eok = abs ~/ 100000000;
  final man = (abs % 100000000) ~/ 10000;
  final rest = abs % 10000;
  final parts = <String>[
    if (eok > 0) '${_thousands.format(eok)}억',
    if (man > 0) '${_thousands.format(man)}만',
    if (rest > 0) _thousands.format(rest),
  ];
  return '$sign${parts.join(' ')}';
}

/// 콤마 포함 문자열 → 정수 (숫자 없으면 null)
int? parseAmount(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.tryParse(digits);
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
