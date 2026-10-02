import 'package:firedom/core/currency.dart';
import 'package:firedom/core/money_format.dart';
import 'package:firedom/core/ym.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    test('fromCode: 모르는 코드·null은 KRW (기존 설치 호환)', () {
      expect(Currency.fromCode(null), Currency.krw);
      expect(Currency.fromCode('XYZ'), Currency.krw);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('JPY'), Currency.jpy);
    });

    test('defaultForLanguage: ko→KRW, ja→JPY, 그 외→USD', () {
      expect(Currency.defaultForLanguage('ko'), Currency.krw);
      expect(Currency.defaultForLanguage('ja'), Currency.jpy);
      expect(Currency.defaultForLanguage('en'), Currency.usd);
      expect(Currency.defaultForLanguage('de'), Currency.usd);
    });

    test('minorPerMajor: USD만 센트', () {
      expect(Currency.krw.minorPerMajor, 1);
      expect(Currency.jpy.minorPerMajor, 1);
      expect(Currency.usd.minorPerMajor, 100);
    });

    test('마일스톤 기준은 5단계 오름차순', () {
      for (final c in Currency.values) {
        expect(c.netWorthTiers.length, 5);
        for (var i = 1; i < 5; i++) {
          expect(c.netWorthTiers[i], greaterThan(c.netWorthTiers[i - 1]));
        }
      }
    });
  });

  group('MoneyFormat ko+KRW (기존 표기와 동일)', () {
    const m = MoneyFormat(Currency.krw, 'ko');
    test('compact', () {
      expect(m.compact(120000000), '1억 2,000만원');
      expect(m.compact(3000000), '300만원');
      expect(m.compact(0), '0원');
      expect(m.compact(-3000000), '−300만원');
    });
    test('full', () {
      expect(m.full(1234567), '1,234,567원');
      expect(m.full(-5000), '−5,000원');
    });
    test('입력 단위', () {
      expect(m.inputSuffix, '원');
      expect(m.inputPrefix, '');
      expect(m.hasLargeInputUnit, isTrue);
      expect(m.largeUnitWord, '만원');
    });
  });

  group('MoneyFormat en+USD (센트 저장)', () {
    const m = MoneyFormat(Currency.usd, 'en');
    test('full: 센트 0이면 생략', () {
      expect(m.full(123456700), r'$1,234,567');
      expect(m.full(1250), r'$12.50');
      expect(m.full(-99), r'−$0.99');
    });
    test('compact', () {
      expect(m.compact(123456700), r'$1.23M');
      expect(m.compact(35000000), r'$350K');
      expect(m.compact(500000), r'$5,000');
      expect(m.compact(100000000), r'$1M');
    });
    test('입력 단위: 접두 기호, 보조 단위 없음', () {
      expect(m.inputPrefix, r'$');
      expect(m.inputSuffix, '');
      expect(m.hasLargeInputUnit, isFalse);
    });
  });

  group('MoneyFormat ja+JPY', () {
    const m = MoneyFormat(Currency.jpy, 'ja');
    test('compact·full', () {
      expect(m.compact(12000000), '1,200万円');
      expect(m.compact(123456789), '1億2,345万6,789円');
      expect(m.full(1234567), '1,234,567円');
      expect(m.largeUnitWord, '万円');
    });
  });

  group('MoneyFormat 교차 조합', () {
    test('ko UI + USD: 억/만 체계에 달러 단위어', () {
      const m = MoneyFormat(Currency.usd, 'ko');
      expect(m.compact(123456700), '123만 4,567달러');
      expect(m.full(1250), '12.50달러');
      expect(m.largeUnitWord, '만 달러');
    });
    test('en UI + KRW: 기호 접두 축약', () {
      const m = MoneyFormat(Currency.krw, 'en');
      expect(m.compact(120000000), '₩120M');
      expect(m.full(1234567), '₩1,234,567');
      expect(m.hasLargeInputUnit, isFalse);
    });
  });

  group('formatYm', () {
    test('언어별', () {
      expect(formatYm(202607), '2026년 7월');
      expect(formatYm(202607, languageCode: 'en'), 'Jul 2026');
      expect(formatYm(202612, languageCode: 'ja'), '2026年12月');
    });
  });

  group('MoneyFormat.axis — 차트 축 라벨', () {
    test('CJK는 단위어를 뺀다 (좁은 축에서 두 줄로 접히지 않게)', () {
      expect(const MoneyFormat(Currency.krw, 'ko').axis(600000000), '6억');
      expect(const MoneyFormat(Currency.jpy, 'ja').axis(60000000), '6,000万');
      expect(const MoneyFormat(Currency.krw, 'ko').axis(0), '0');
    });

    test('영어는 기호가 접두라 compact 그대로', () {
      expect(const MoneyFormat(Currency.usd, 'en').axis(60000000), r'$600K');
    });

    test('가림 모드', () {
      expect(const MoneyFormat(Currency.krw, 'ko', masked: true).axis(600000000),
          '●●●');
    });
  });
}
