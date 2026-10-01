import 'package:firedom/engine/portfolio.dart';
import 'package:firedom/features/common/portfolio_labels.dart';
import 'package:firedom/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 엔진 프리셋의 한국어 label/source와 arb ko 문구가 글자 단위로 같아야 한다.
/// (엔진은 l10n 의존 금지 — UI 쪽 매핑이 어긋나면 "가정 보기" 출처가 틀어진다)
void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));

  test('PortfolioAsset label/source — ko는 엔진 문자열과 동일', () {
    for (final asset in PortfolioAsset.values) {
      expect(portfolioAssetLabel(ko, asset), asset.label, reason: asset.key);
      expect(portfolioAssetSource(ko, asset), asset.source, reason: asset.key);
    }
  });

  test('PortfolioExample label — ko는 엔진 문자열과 동일', () {
    for (final example in PortfolioExample.values) {
      expect(portfolioExampleLabel(ko, example), example.label,
          reason: example.name);
    }
  });

  test('en/ja 라벨·출처는 모두 비어 있지 않고 "추천" 표현이 없다', () {
    for (final code in ['en', 'ja']) {
      final l10n = lookupAppLocalizations(Locale(code));
      for (final asset in PortfolioAsset.values) {
        expect(portfolioAssetLabel(l10n, asset), isNotEmpty);
        expect(portfolioAssetSource(l10n, asset), isNotEmpty);
      }
      for (final example in PortfolioExample.values) {
        final label = portfolioExampleLabel(l10n, example);
        expect(label, isNotEmpty);
        expect(label.toLowerCase(), isNot(contains('recommend')));
        expect(label, isNot(contains('推奨')));
      }
    }
  });
}
