import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/providers.dart';
import '../../data/repositories/settings_store.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';
import 'onboarding_draft.dart';
import 'onboarding_result_screen.dart';

/// 금액 입력 단위 — [large]는 통화의 보조 단위(만원·万円), [base]는 주 단위(원·円·$)
enum _MoneyUnit { large, base }

const _stepCount = 4;

/// 0번 문항(나이)만 숫자, 나머지는 금액
bool _isMoneyStep(int step) => step != 0;

String _stepTitle(AppLocalizations l10n, int step) => switch (step) {
      0 => l10n.onbStepAgeTitle,
      1 => l10n.onbStepIncomeTitle,
      2 => l10n.onbStepExpenseTitle,
      _ => l10n.onbStepAssetsTitle,
    };

String _stepSubtitle(AppLocalizations l10n, int step) => switch (step) {
      0 => l10n.onbStepAgeSubtitle,
      1 => l10n.onbStepIncomeSubtitle,
      2 => l10n.onbStepExpenseSubtitle,
      _ => l10n.onbStepAssetsSubtitle,
    };

/// S1. 온보딩 — 입력 (PRD)
///
/// 4문항 1화면씩. 계정·권한 요청 없음. 이탈 시 값 보존, 재실행 시 재개.
/// 첫 문항 위에서 통화를 고를 수 있다 — 선택 즉시 설정에 저장되므로
/// 결과 화면·계획 생성은 항상 저장된 통화를 본다.
class OnboardingScreen extends ConsumerStatefulWidget {
  static const path = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = TextEditingController();
  _MoneyUnit _unit = _MoneyUnit.large;
  String? _error;

  /// 설정에서 읽은(또는 기기 언어로 정한) 통화. 로드 전에는 null
  Currency? _currency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 통화 결정 → 재개 시 진행 중이던 문항의 저장값 복원
  Future<void> _init() async {
    final store = ref.read(settingsStoreProvider);
    final saved = await store.get<String>(SettingKeys.currency);
    if (!mounted) return;
    Currency currency;
    if (saved != null) {
      currency = Currency.fromCode(saved);
    } else {
      currency = Currency.defaultForLanguage(
          Localizations.localeOf(context).languageCode);
      // 계획 생성 전에 통화가 저장돼 있어야 한다 — 기본값도 바로 기록
      await store.set(SettingKeys.currency, currency.code);
      if (!mounted) return;
    }
    setState(() => _currency = currency);
    _loadStepValue(ref.read(onboardingDraftProvider).step);
  }

  Currency get _effectiveCurrency =>
      _currency ??
      Currency.defaultForLanguage(
          Localizations.localeOf(context).languageCode);

  MoneyFormat get _money => MoneyFormat(
      _effectiveCurrency, Localizations.localeOf(context).languageCode);

  /// 보조 단위 1 = 최소 단위 몇 개 (KRW 만원 = 10,000원, JPY 万円 = 10,000엔)
  int get _largeMinor =>
      (_effectiveCurrency.largeUnit ?? 1) * _effectiveCurrency.minorPerMajor;

  Future<void> _selectCurrency(Currency currency) async {
    setState(() {
      _currency = currency;
      _unit = _MoneyUnit.large;
    });
    await ref
        .read(settingsStoreProvider)
        .set(SettingKeys.currency, currency.code);
  }

  void _loadStepValue(int step) {
    final draft = ref.read(onboardingDraftProvider);
    final value = draft.valueAt(step);
    final money = _money;
    final minorPerMajor = _effectiveCurrency.minorPerMajor;
    setState(() {
      _error = null;
      if (value == null) {
        _controller.text = '';
        _unit = _MoneyUnit.large;
      } else if (!_isMoneyStep(step)) {
        _controller.text = '$value';
      } else if (money.hasLargeInputUnit &&
          value > 0 &&
          value % _largeMinor == 0) {
        _unit = _MoneyUnit.large;
        _controller.text = formatWithComma(value ~/ _largeMinor);
      } else {
        _unit = _MoneyUnit.base;
        _controller.text = formatWithComma(value ~/ minorPerMajor);
      }
    });
  }

  /// 입력값 → 저장 단위(통화의 최소 단위) 정수
  int? _parsedValue(int step) {
    final raw = parseAmount(_controller.text);
    if (raw == null) return null;
    if (!_isMoneyStep(step)) return raw;
    final useLarge = _money.hasLargeInputUnit && _unit == _MoneyUnit.large;
    return useLarge
        ? raw * _largeMinor
        : raw * _effectiveCurrency.minorPerMajor;
  }

  String? _validate(int step, int value) {
    final l10n = context.l10n;
    if (step == 0 && (value < 1 || value > 85)) {
      return l10n.onbErrorAgeRange;
    }
    if (value > 1000000000000000) {
      return l10n.onbErrorTooLarge;
    }
    return null;
  }

  void _goNext(int step) {
    final value = _parsedValue(step);
    if (value == null) return;
    final error = _validate(step, value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final notifier = ref.read(onboardingDraftProvider.notifier);
    notifier.setValueAt(step, value);
    if (step < _stepCount - 1) {
      notifier.setStep(step + 1);
      _loadStepValue(step + 1);
    } else {
      context.push(OnboardingResultScreen.path);
    }
  }

  void _goBack(int step) {
    // 입력 중이던 값도 보존
    final value = _parsedValue(step);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    if (value != null && _validate(step, value) == null) {
      notifier.setValueAt(step, value);
    }
    notifier.setStep(step - 1);
    _loadStepValue(step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final step = ref.watch(onboardingDraftProvider).step;
    final isMoney = _isMoneyStep(step);
    final theme = Theme.of(context);
    final isLast = step == _stepCount - 1;
    final money = _money;
    final showUnitToggle = isMoney && money.hasLargeInputUnit;
    final suffix = isMoney
        ? (showUnitToggle && _unit == _MoneyUnit.large
            ? money.largeUnitWord
            : money.inputSuffix)
        : l10n.ageSuffix;
    final prefix = isMoney ? money.inputPrefix : '';

    return Scaffold(
      appBar: AppBar(
        leading: step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goBack(step),
              )
            : null,
        title: Text('${step + 1} / $_stepCount'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (step + 1) / _stepCount,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step == 0) ...[
                const SizedBox(height: 8),
                _CurrencyPicker(
                  value: _effectiveCurrency,
                  onChanged: _selectCurrency,
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 24),
              Text(_stepTitle(l10n, step),
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                _stepSubtitle(l10n, step),
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: ValueKey('onboarding-input-$step'),
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixText: prefix.isEmpty ? null : prefix,
                  suffixText: suffix.isEmpty ? null : suffix,
                  errorText: _error,
                  helperText: isMoney ? _helperText(step) : null,
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _goNext(step),
              ),
              if (showUnitToggle) ...[
                const SizedBox(height: 12),
                SegmentedButton<_MoneyUnit>(
                  segments: [
                    ButtonSegment(
                      value: _MoneyUnit.large,
                      label: Text(l10n.onbUnitSegment(money.largeUnitWord)),
                    ),
                    ButtonSegment(
                      value: _MoneyUnit.base,
                      label: Text(l10n.onbUnitSegment(money.unitWord)),
                    ),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (selection) {
                    setState(() => _unit = selection.first);
                  },
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _goNext(step),
                  child: Text(isLast ? l10n.onbSeeResult : l10n.commonNext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _helperText(int step) {
    final value = _parsedValue(step);
    if (value == null || value == 0) return null;
    return context.l10n.onbHelperEquals(_money.compact(value));
  }
}

/// 통화 선택 — 드롭다운(텍스트필드가 아니므로 문항 입력과 섞이지 않는다)
class _CurrencyPicker extends StatelessWidget {
  final Currency value;
  final ValueChanged<Currency> onChanged;

  const _CurrencyPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.onbCurrencyLabel,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Currency>(
          key: const ValueKey('onboarding-currency'),
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            for (final c in Currency.values)
              DropdownMenuItem(value: c, child: Text(_label(l10n, c))),
          ],
          onChanged: (c) {
            if (c != null) onChanged(c);
          },
        ),
      ),
    );
  }

  static String _label(AppLocalizations l10n, Currency c) => switch (c) {
        Currency.krw => l10n.currencyKrw,
        Currency.usd => l10n.currencyUsd,
        Currency.jpy => l10n.currencyJpy,
      };
}
