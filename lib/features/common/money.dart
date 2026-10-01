import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/currency.dart';
import '../../core/money_format.dart';
import '../../data/db/providers.dart';

export '../../core/currency.dart';
export '../../core/money_format.dart';

/// 현재 통화 설정 + 현재 UI 언어 + 금액 가림 설정으로 만든 금액 포매터.
/// 화면에서 금액을 그릴 때는 항상 이걸 쓴다 (`formatKoreanMoney` 직접 호출 금지).
/// 가림이 켜져 있으면 `compact`/`full`이 ●●●를 돌려주므로 화면마다 따로 분기할 필요가 없다.
MoneyFormat moneyFormatOf(BuildContext context, WidgetRef ref) {
  final currency = ref.watch(currencyProvider).value ?? Currency.fallback;
  final masked = ref.watch(maskAmountsProvider).value ?? false;
  return MoneyFormat(
    currency,
    Localizations.localeOf(context).languageCode,
    masked: masked,
  );
}

/// 현재 통화 (설정이 아직 로드되지 않았으면 KRW)
Currency currencyOf(WidgetRef ref) =>
    ref.watch(currencyProvider).value ?? Currency.fallback;
