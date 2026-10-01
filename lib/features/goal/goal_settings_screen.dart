import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/db/providers.dart';
import '../../data/home_widget_sync.dart';
import '../../data/repositories/plan_repository.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';

const _fireTypes = ['lean', 'fat', 'coast', 'barista', 'custom'];

String _fireTypeLabel(AppLocalizations l10n, String type) => switch (type) {
      'lean' => l10n.goalFireTypeLean,
      'fat' => l10n.goalFireTypeFat,
      'coast' => l10n.goalFireTypeCoast,
      'barista' => l10n.goalFireTypeBarista,
      _ => l10n.goalFireTypeCustom,
    };

enum _ReturnChoice { conservative, neutral, aggressive, custom }

/// S7. 목표 설정 — 상세 (PRD)
///
/// 온보딩의 간이 가정을 정교화한다. 저장 = 새 리비전 append —
/// 홈 궤도(계획 곡선)에 반영되고 변경 이력이 마커로 남는다.
class GoalSettingsScreen extends ConsumerStatefulWidget {
  static const path = '/goal';

  const GoalSettingsScreen({super.key});

  @override
  ConsumerState<GoalSettingsScreen> createState() =>
      _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  bool _initialized = false;
  String _fireType = 'custom';
  int _swrBp = 400;
  _ReturnChoice _returnChoice = _ReturnChoice.neutral;
  int _customRealReturnBp = 400;
  int _volatilityBp = 1200;
  bool _npsEnabled = false;

  final _savingController = TextEditingController();
  final _spendController = TextEditingController();
  final _nominalController = TextEditingController();
  final _inflationController = TextEditingController();
  final _npsAmountController = TextEditingController();
  final _npsAgeController = TextEditingController(text: '65');
  final _lifeController = TextEditingController(text: '90');

  @override
  void dispose() {
    _savingController.dispose();
    _spendController.dispose();
    _nominalController.dispose();
    _inflationController.dispose();
    _npsAmountController.dispose();
    _npsAgeController.dispose();
    _lifeController.dispose();
    super.dispose();
  }

  /// 금액 필드는 통화의 주 단위(원·$·円)로 입력받고 최소 단위로 저장한다
  void _initFrom(Plan plan, Currency currency) {
    if (_initialized) return;
    _initialized = true;
    final unit = currency.minorPerMajor;
    _fireType = _fireTypes.contains(plan.fireType) ? plan.fireType : 'custom';
    _swrBp = plan.swrBp.clamp(300, 500);
    _volatilityBp = plan.volatilityBp;
    _returnChoice = switch ((plan.realReturnBp, plan.volatilityBp)) {
      (250, 800) => _ReturnChoice.conservative,
      (400, 1200) => _ReturnChoice.neutral,
      (550, 1700) => _ReturnChoice.aggressive,
      _ => _ReturnChoice.custom,
    };
    _customRealReturnBp = plan.realReturnBp;
    _savingController.text = formatWithComma(plan.monthlySaving ~/ unit);
    _spendController.text = formatWithComma(plan.monthlySpendRetire ~/ unit);
    _lifeController.text = '${plan.lifeExpectancy}';
    if (plan.npsMonthly != null) {
      _npsEnabled = true;
      _npsAmountController.text = formatWithComma(plan.npsMonthly! ~/ unit);
      _npsAgeController.text = '${plan.npsStartAge ?? 65}';
    }
  }

  int _realReturnBp() {
    return switch (_returnChoice) {
      _ReturnChoice.conservative => ReturnPreset.conservative.realReturnBp,
      _ReturnChoice.neutral => ReturnPreset.neutral.realReturnBp,
      _ReturnChoice.aggressive => ReturnPreset.aggressive.realReturnBp,
      _ReturnChoice.custom => _customRealReturnBp,
    };
  }

  int _effectiveVolatilityBp() {
    return switch (_returnChoice) {
      _ReturnChoice.conservative => ReturnPreset.conservative.volatilityBp,
      _ReturnChoice.neutral => ReturnPreset.neutral.volatilityBp,
      _ReturnChoice.aggressive => ReturnPreset.aggressive.volatilityBp,
      _ReturnChoice.custom => _volatilityBp,
    };
  }

  void _recomputeCustomReturn() {
    final nominal = double.tryParse(_nominalController.text);
    final inflation = double.tryParse(_inflationController.text);
    if (nominal == null || inflation == null) return;
    setState(() {
      _customRealReturnBp = fisherRealBp(
        nominalBp: (nominal * 100).round(),
        inflationBp: (inflation * 100).round(),
      );
    });
  }

  PlanInput? _buildInput(Plan plan, Currency currency) {
    final baseInput = planInputOf(plan);
    final unit = currency.minorPerMajor;
    final saving = parseAmount(_savingController.text);
    final spend = parseAmount(_spendController.text);
    final life = int.tryParse(_lifeController.text);
    if (saving == null || spend == null || spend <= 0) return null;
    if (life == null || life <= baseInput.age0 || life > 120) return null;

    NpsInput? nps;
    if (_npsEnabled) {
      final amount = parseAmount(_npsAmountController.text);
      final age = int.tryParse(_npsAgeController.text);
      if (amount == null || amount <= 0 || age == null) return null;
      nps = NpsInput(monthlyAmount: amount * unit, startAge: age);
    }

    return PlanInput(
      age0: baseInput.age0,
      currentAssets: plan.currentAssets,
      monthlySaving: saving * unit,
      realReturnBp: _realReturnBp(),
      monthlySpendRetire: spend * unit,
      swrBp: _swrBp,
      lifeExpectancy: life,
      nps: nps,
      volatilityBp: _effectiveVolatilityBp(),
    );
  }

  Future<void> _save(Plan plan, Currency currency) async {
    final input = _buildInput(plan, currency);
    if (input == null) return;
    await ref.read(planRepositoryProvider).revisePlan(
          base: plan,
          input: input,
          fireType: _fireType,
        );
    await ref.read(homeWidgetSyncProvider)(ref.read(databaseProvider));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.goalSavedSnack)),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = ref.watch(activePlanRowProvider).value;
    final currencyAsync = ref.watch(currencyProvider);

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.goalTitle)),
        body: Center(child: Text(l10n.goalNoActivePlan)),
      );
    }
    // 금액 필드 복원은 통화를 알아야 한다 — 설정 로드 전에는 빈 화면
    if (!currencyAsync.hasValue) {
      return Scaffold(appBar: AppBar(title: Text(l10n.goalTitle)));
    }
    final currency = currencyAsync.value!;
    final money = moneyFormatOf(context, ref);
    final prefix = money.inputPrefix.isEmpty ? null : money.inputPrefix;
    final suffix = money.inputSuffix.isEmpty ? null : money.inputSuffix;
    final ageSuffix = l10n.ageSuffix.isEmpty ? null : l10n.ageSuffix;
    _initFrom(plan, currency);

    final input = _buildInput(plan, currency);
    final result = input == null ? null : solvePlan(input);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PreviewCard(input: input, result: result),
            const SizedBox(height: 16),
            Text(l10n.goalFireType, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final type in _fireTypes)
                  ChoiceChip(
                    label: Text(_fireTypeLabel(l10n, type)),
                    selected: _fireType == type,
                    onSelected: (_) => setState(() => _fireType = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('goal-saving-field'),
              controller: _savingController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                labelText: l10n.goalMonthlySaving,
                prefixText: prefix,
                suffixText: suffix,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('goal-spend-field'),
              controller: _spendController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: InputDecoration(
                labelText: l10n.goalRetireSpend,
                prefixText: prefix,
                suffixText: suffix,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.goalSwr, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${(_swrBp / 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleSmall!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              key: const ValueKey('swr-slider'),
              value: _swrBp.toDouble(),
              min: 300,
              max: 500,
              divisions: 20,
              onChanged: (value) => setState(() => _swrBp = value.round()),
            ),
            const SizedBox(height: 8),
            Text(l10n.goalExpectedReturn, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_ReturnChoice>(
              segments: [
                ButtonSegment(
                    value: _ReturnChoice.conservative,
                    label: Text(l10n.goalReturnConservative)),
                ButtonSegment(
                    value: _ReturnChoice.neutral,
                    label: Text(l10n.goalReturnNeutral)),
                ButtonSegment(
                    value: _ReturnChoice.aggressive,
                    label: Text(l10n.goalReturnAggressive)),
                ButtonSegment(
                    value: _ReturnChoice.custom,
                    label: Text(l10n.goalReturnCustom)),
              ],
              selected: {_returnChoice},
              onSelectionChanged: (selection) =>
                  setState(() => _returnChoice = selection.first),
            ),
            const SizedBox(height: 8),
            if (_returnChoice == _ReturnChoice.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('nominal-field'),
                      controller: _nominalController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.goalNominalReturn,
                        suffixText: '%',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _recomputeCustomReturn(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('inflation-field'),
                      controller: _inflationController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.goalInflation,
                        suffixText: '%',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _recomputeCustomReturn(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                // 피셔 방정식 (R4)
                l10n.goalRealReturnFisher(
                    (_customRealReturnBp / 100).toStringAsFixed(2)),
                style: theme.textTheme.bodySmall,
              ),
            ] else
              Text(
                l10n.goalReturnSummary(
                  (_realReturnBp() / 100).toStringAsFixed(1),
                  (_effectiveVolatilityBp() / 100).toStringAsFixed(0),
                ),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('life-field'),
              controller: _lifeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.goalLifeExpectancy,
                suffixText: ageSuffix,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.goalPensionToggle),
              subtitle: Text(l10n.goalPensionHint),
              value: _npsEnabled,
              onChanged: (value) => setState(() => _npsEnabled = value),
            ),
            if (_npsEnabled) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: const ValueKey('nps-amount-field'),
                      controller: _npsAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: l10n.goalPensionAmount,
                        prefixText: prefix,
                        suffixText: suffix,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      key: const ValueKey('nps-age-field'),
                      controller: _npsAgeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.goalPensionStartAge,
                        suffixText: ageSuffix,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: input == null ? null : () => _save(plan, currency),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.goalSaveButton),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.goalSaveHint,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends ConsumerWidget {
  final PlanInput? input;
  final FireResult? result;

  const _PreviewCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final input = this.input;
    final result = this.result;

    if (input == null || result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.goalCheckInputs, style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final months = result.monthsToFire;
    final headline = months == null
        ? l10n.onbHeadlineUnreachable
        : months == 0
            ? l10n.goalAlreadyFire
            : l10n.goalFireAge(input.age0 + months ~/ 12);

    final nps = input.nps;
    String? bridgeSummary;
    String? npsEffect;
    if (nps != null) {
      // 브릿지 구간 분리 계산 표시 (PRD S7 수용 기준)
      final bridgeSpend = money.compact(input.monthlySpendRetire);
      final afterSpend =
          money.compact(input.monthlySpendRetire - nps.monthlyAmount);
      bridgeSummary = '${l10n.goalBridgeBefore(nps.startAge - 1, bridgeSpend)}\n'
          '${l10n.goalBridgeAfter(nps.startAge, afterSpend, money.compact(nps.monthlyAmount))}';

      final withoutNps =
          solveFireByFeasibility(input.copyWith(clearNps: true));
      final withNps = result.monthsToFire;
      final without = withoutNps.monthsToFire;
      if (withNps != null && without != null && without > withNps) {
        npsEffect = l10n.goalPensionEffect(without - withNps);
      }
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.goalPreviewTitle, style: theme.textTheme.labelLarge),
            Text(
              headline,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (months != null && months > 0)
              Text(
                l10n.goalPreviewSummary(
                  l10n.yearsMonthsLabel(months ~/ 12, months % 12),
                  money.compact(result.fireNumber),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            if (bridgeSummary != null) ...[
              const SizedBox(height: 8),
              Text(bridgeSummary, style: theme.textTheme.bodySmall),
            ],
            if (npsEffect != null) ...[
              const SizedBox(height: 4),
              Text(
                npsEffect,
                style: theme.textTheme.bodySmall!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
