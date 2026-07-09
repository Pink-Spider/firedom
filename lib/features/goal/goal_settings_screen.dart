import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import '../../data/db/database.dart';
import '../../data/db/providers.dart';
import '../../data/repositories/plan_repository.dart';
import '../../engine/engine.dart';

const _fireTypeLabels = {
  'lean': '린',
  'fat': '팻',
  'coast': '코스트',
  'barista': '바리스타',
  'custom': '직접 설정',
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

  void _initFrom(Plan plan) {
    if (_initialized) return;
    _initialized = true;
    _fireType = _fireTypeLabels.containsKey(plan.fireType)
        ? plan.fireType
        : 'custom';
    _swrBp = plan.swrBp.clamp(300, 500);
    _volatilityBp = plan.volatilityBp;
    _returnChoice = switch ((plan.realReturnBp, plan.volatilityBp)) {
      (250, 800) => _ReturnChoice.conservative,
      (400, 1200) => _ReturnChoice.neutral,
      (550, 1700) => _ReturnChoice.aggressive,
      _ => _ReturnChoice.custom,
    };
    _customRealReturnBp = plan.realReturnBp;
    _savingController.text = formatWithComma(plan.monthlySaving);
    _spendController.text = formatWithComma(plan.monthlySpendRetire);
    _lifeController.text = '${plan.lifeExpectancy}';
    if (plan.npsMonthly != null) {
      _npsEnabled = true;
      _npsAmountController.text = formatWithComma(plan.npsMonthly!);
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

  PlanInput? _buildInput(Plan plan) {
    final baseInput = planInputOf(plan);
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
      nps = NpsInput(monthlyAmount: amount, startAge: age);
    }

    return PlanInput(
      age0: baseInput.age0,
      currentAssets: plan.currentAssets,
      monthlySaving: saving,
      realReturnBp: _realReturnBp(),
      monthlySpendRetire: spend,
      swrBp: _swrBp,
      lifeExpectancy: life,
      nps: nps,
      volatilityBp: _effectiveVolatilityBp(),
    );
  }

  Future<void> _save(Plan plan) async {
    final input = _buildInput(plan);
    if (input == null) return;
    await ref.read(planRepositoryProvider).revisePlan(
          base: plan,
          input: input,
          fireType: _fireType,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계획을 업데이트했어요 — 궤도에 반영됩니다')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = ref.watch(activePlanRowProvider).value;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('목표 설정')),
        body: const Center(child: Text('활성 계획이 없어요')),
      );
    }
    _initFrom(plan);

    final input = _buildInput(plan);
    final result = input == null ? null : solvePlan(input);

    return Scaffold(
      appBar: AppBar(title: const Text('목표 설정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PreviewCard(input: input, result: result),
            const SizedBox(height: 16),
            Text('FIRE 유형', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in _fireTypeLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _fireType == entry.key,
                    onSelected: (_) =>
                        setState(() => _fireType = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('goal-saving-field'),
              controller: _savingController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: '월 저축액',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('goal-spend-field'),
              controller: _spendController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: const InputDecoration(
                labelText: '은퇴 후 월 생활비',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('안전인출률', style: theme.textTheme.titleSmall),
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
            Text('기대수익률 (실질)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_ReturnChoice>(
              segments: const [
                ButtonSegment(
                    value: _ReturnChoice.conservative, label: Text('보수')),
                ButtonSegment(
                    value: _ReturnChoice.neutral, label: Text('중립')),
                ButtonSegment(
                    value: _ReturnChoice.aggressive, label: Text('공격')),
                ButtonSegment(
                    value: _ReturnChoice.custom, label: Text('직접')),
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
                      decoration: const InputDecoration(
                        labelText: '명목수익률',
                        suffixText: '%',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: '인플레이션',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _recomputeCustomReturn(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                // 피셔 방정식 (R4)
                '실질수익률 ${(_customRealReturnBp / 100).toStringAsFixed(2)}% '
                '(피셔 방정식으로 계산)',
                style: theme.textTheme.bodySmall,
              ),
            ] else
              Text(
                '실질 ${(_realReturnBp() / 100).toStringAsFixed(1)}% · '
                '변동성 ${(_effectiveVolatilityBp() / 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('life-field'),
              controller: _lifeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '기대수명',
                suffixText: '세',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('국민연금 반영'),
              subtitle: const Text(
                  '예상 수령액은 통합연금포털(fss.or.kr)에서 확인할 수 있어요'),
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
                      decoration: const InputDecoration(
                        labelText: '예상 월 수령액',
                        suffixText: '원',
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: '수령 나이',
                        suffixText: '세',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: input == null ? null : () => _save(plan),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장하기'),
            ),
            const SizedBox(height: 8),
            Text(
              '저장하면 새 리비전으로 기록되고, 홈 궤도 차트에 변경 시점이 표시돼요.',
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

class _PreviewCard extends StatelessWidget {
  final PlanInput? input;
  final FireResult? result;

  const _PreviewCard({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final input = this.input;
    final result = this.result;

    if (input == null || result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('입력값을 확인해주세요', style: theme.textTheme.bodyMedium),
        ),
      );
    }

    final months = result.monthsToFire;
    final headline = months == null
        ? '100년 안에 도달이 어려워요'
        : months == 0
            ? '이미 FIRE 도달!'
            : 'FIRE 나이 ${input.age0 + months ~/ 12}세';

    final nps = input.nps;
    String? bridgeSummary;
    String? npsEffect;
    if (nps != null) {
      // 브릿지 구간 분리 계산 표시 (PRD S7 수용 기준)
      final bridgeSpend = formatKoreanMoney(input.monthlySpendRetire);
      final afterSpend =
          formatKoreanMoney(input.monthlySpendRetire - nps.monthlyAmount);
      bridgeSummary = '수령 전(~${nps.startAge - 1}세): 월 $bridgeSpend원 (생활비 전액)\n'
          '수령 후(${nps.startAge}세~): 월 $afterSpend원 '
          '(생활비 − 연금 ${formatKoreanMoney(nps.monthlyAmount)}원)';

      final withoutNps =
          solveFireByFeasibility(input.copyWith(clearNps: true));
      final withNps = result.monthsToFire;
      final without = withoutNps.monthsToFire;
      if (withNps != null && without != null && without > withNps) {
        npsEffect = '연금 반영으로 은퇴가 ${without - withNps}개월 앞당겨져요';
      }
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 가정이라면', style: theme.textTheme.labelLarge),
            Text(
              headline,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (months != null && months > 0)
              Text(
                '${months ~/ 12}년 ${months % 12}개월 후 · '
                '목표 자산 ${formatKoreanMoney(result.fireNumber)}원',
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
