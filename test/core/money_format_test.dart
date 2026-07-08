import 'package:firedom/core/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatKoreanMoney', () {
    test('억·만·원 조합', () {
      expect(formatKoreanMoney(900000000), '9억');
      expect(formatKoreanMoney(120000000), '1억 2,000만');
      expect(formatKoreanMoney(3000000), '300만');
      expect(formatKoreanMoney(2742857143), '27억 4,285만 7,143');
      expect(formatKoreanMoney(5000), '5,000');
      expect(formatKoreanMoney(0), '0');
    });

    test('음수', () {
      expect(formatKoreanMoney(-3000000), '−300만');
    });
  });

  group('parseAmount', () {
    test('콤마·비숫자 제거', () {
      expect(parseAmount('1,234,567'), 1234567);
      expect(parseAmount('500'), 500);
      expect(parseAmount(''), null);
      expect(parseAmount('abc'), null);
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    TextEditingValue format(String text) =>
        ThousandsSeparatorInputFormatter().formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: text),
        );

    test('천 단위 콤마 자동 표기 (PRD S1)', () {
      expect(format('1234567').text, '1,234,567');
      expect(format('500').text, '500');
      expect(format('').text, '');
    });
  });
}
