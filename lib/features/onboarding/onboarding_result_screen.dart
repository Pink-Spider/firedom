import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ym.dart';
import '../../data/db/providers.dart';
import '../../data/home_widget_sync.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';
import '../home/home_screen.dart';
import 'onboarding_draft.dart';

/// S2. 온보딩 — 결과 (PRD) ★ aha moment
///
/// FIRE 나이 헤드라인 + 성장 곡선 + What-if 슬라이더(즉시 재계산, A5).
class OnboardingResultScreen extends ConsumerStatefulWidget {
  static const path = '/onboarding/result';

  const OnboardingResultScreen({super.key});

  @override
  ConsumerState<OnboardingResultScreen> createState() =>
      _OnboardingResultScreenState();
}

class _OnboardingResultScreenState
    extends ConsumerState<OnboardingResultScreen> {
  /// What-if: 월 추가 저축 (통화 최소 단위)
  int _extraSaving = 0;

  PlanInput _planOf(OnboardingDraft draft, {required int extraSaving}) {
    return PlanInput(
      age0: draft.age!,
      currentAssets: draft.currentAssets!,
      monthlySaving: draft.monthlySaving + extraSaving,
      realReturnBp: ReturnPreset.neutral.realReturnBp,
      monthlySpendRetire: draft.monthlyExpense!,
      volatilityBp: ReturnPreset.neutral.volatilityBp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = ref.watch(onboardingDraftProvider);
    if (!draft.isComplete) {
      // 딥링크 등으로 입력 없이 진입한 경우
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.onbNeedInputBack),
          ),
        ),
      );
    }

    // 지출 ≥ 소득: 계산 불가 안내 (크래시·음수 연도 금지, PRD S2)
    if (draft.monthlySaving <= 0) {
      return _NoSavingView(
        onAdjustExpense: () {
          ref.read(onboardingDraftProvider.notifier).setStep(2);
          context.pop();
        },
      );
    }

    final plan = _planOf(draft, extraSaving: _extraSaving);
    final result = solveFireBySwr(plan);
    final baseResult = _extraSaving == 0
        ? result
        : solveFireBySwr(_planOf(draft, extraSaving: 0));

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _Headline(age0: plan.age0, monthsToFire: result.monthsToFire),
            const SizedBox(height: 24),
            _FireNumberCard(
              monthlyExpense: draft.monthlyExpense!,
              swrBp: plan.swrBp,
              fireNumber: result.fireNumber,
            ),
            if (result.isReachable && result.monthsToFire! > 0) ...[
              const SizedBox(height: 24),
              _TrajectoryChart(result: result, age0: plan.age0),
            ],
            const SizedBox(height: 24),
            _WhatIfSlider(
              extraSaving: _extraSaving,
              age0: plan.age0,
              result: result,
              baseResult: baseResult,
              onChanged: (value) => setState(() => _extraSaving = value),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => _showAssumptions(context, plan),
                child: Text(l10n.onbShowAssumptions),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _startPlan(plan),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.onbStartPlan),
            ),
            const SizedBox(height: 12),
            // 면책은 '가정 보기' 시트뿐 아니라 결과 본문에도 (제품 원칙)
            Text(
              l10n.disclaimerShort,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPlan(PlanInput plan) async {
    final ym = nowYm();
    await ref.read(planRepositoryProvider).createPlan(
          input: plan,
          birthYm: birthYmFromAge(plan.age0, ym),
          startedYm: ym,
        );
    await ref.read(onboardingDraftProvider.notifier).clear();
    await ref.read(homeWidgetSyncProvider)(ref.read(databaseProvider));
    if (mounted) context.go(HomeScreen.path);
  }

  void _showAssumptions(BuildContext context, PlanInput plan) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onbAssumptionsTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _AssumptionRow(
              l10n.onbAssumptionRealReturn,
              l10n.onbAssumptionRealReturnValue(
                  (plan.realReturnBp / 100).toStringAsFixed(1)),
            ),
            _AssumptionRow(
              l10n.onbAssumptionSwr,
              '${(plan.swrBp / 100).toStringAsFixed(1)}%',
            ),
            _AssumptionRow(
                l10n.goalLifeExpectancy, l10n.ageLabel(plan.lifeExpectancy)),
            _AssumptionRow(l10n.onbAssumptionMoneyBasis,
                l10n.onbAssumptionMoneyBasisValue),
            _AssumptionRow(
                l10n.goalRetireSpend, l10n.onbAssumptionRetireSpendValue),
            const SizedBox(height: 16),
            Text(
              '${l10n.disclaimerSimulation} ${l10n.onbAssumptionsEditHint}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final int age0;
  final int? monthsToFire;

  const _Headline({required this.age0, required this.monthsToFire});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final months = monthsToFire;

    if (months == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onbHeadlineUnreachablePrefix,
              style: theme.textTheme.titleMedium),
          Text(
            l10n.onbHeadlineUnreachable,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onbHeadlineUnreachableHint,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (months == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onbCongrats, style: theme.textTheme.titleMedium),
          Text(l10n.onbAlreadyFire,
              style: theme.textTheme.headlineMedium!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
        ],
      );
    }

    final fireAge = age0 + months ~/ 12;
    final years = months ~/ 12;
    final remainMonths = months % 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onbYourFireAge, style: theme.textTheme.titleMedium),
        Text(
          l10n.ageLabel(fireAge),
          style: theme.textTheme.displayLarge!.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          remainMonths == 0
              ? l10n.onbYearsLater(years)
              : l10n.onbYearsMonthsLater(years, remainMonths),
          style: theme.textTheme.titleMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FireNumberCard extends ConsumerWidget {
  final int monthlyExpense;
  final int swrBp;
  final int fireNumber;

  const _FireNumberCard({
    required this.monthlyExpense,
    required this.swrBp,
    required this.fireNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final swrPercent = (swrBp / 100).toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onbFireNumberTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              money.compact(fireNumber),
              style: theme.textTheme.headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.onbFireNumberBasis(money.compact(monthlyExpense), swrPercent),
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

class _TrajectoryChart extends ConsumerWidget {
  final FireResult result;
  final int age0;

  const _TrajectoryChart({required this.result, required this.age0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final trajectory = result.assetsByMonth;

    // 세로축 단위: 억/億 단위 통화(CJK UI)는 1억, 그 외는 주 단위 1,000 (→ "$900K")
    final useHundredMillion = money.hasLargeInputUnit;
    final axisUnit = useHundredMillion
        ? 100000000 * money.currency.minorPerMajor
        : 1000 * money.currency.minorPerMajor;
    String axisLabel(double value) {
      final n = value.toInt();
      return useHundredMillion
          ? l10n.onbAxisHundredMillion(n)
          : money.compact(n * axisUnit);
    }

    // 연 단위로 다운샘플 + 마지막 점(FIRE 도달)
    final spots = <FlSpot>[
      for (var m = 0; m < trajectory.length; m += 12)
        FlSpot(m / 12, trajectory[m] / axisUnit),
      FlSpot(
        (trajectory.length - 1) / 12,
        trajectory.last / axisUnit,
      ),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          // 축 하한 0 고정 — 자동이면 최솟값 라벨이 눈금 라벨과 겹친다 (home_screen 참고)
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  // 끝점 라벨은 마지막 눈금과 겹치므로 생략 (fl_chart가 max에 별도로 그림)
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    axisLabel(value),
                    style: theme.textTheme.labelSmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  // 끝점 라벨은 마지막 눈금과 겹치므로 생략 (fl_chart가 max에 별도로 그림)
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    l10n.ageLabel(age0 + value.toInt()),
                    style: theme.textTheme.labelSmall,
                  );
                },
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatIfSlider extends ConsumerWidget {
  final int extraSaving;
  final int age0;
  final FireResult result;
  final FireResult baseResult;
  final ValueChanged<int> onChanged;

  const _WhatIfSlider({
    required this.extraSaving,
    required this.age0,
    required this.result,
    required this.baseResult,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    // 슬라이더 한 칸 = 통화별 월 금액 단위의 절반 (KRW 5만원), 최대 30칸
    final step = currencyOf(ref).monthlyStep;
    final maxExtra = 30 * step;

    String effectLabel() {
      if (extraSaving == 0) return l10n.onbWhatIfMoveSlider;
      if (result.monthsToFire == null) return l10n.onbWhatIfStillUnreachable;
      final fireAge = age0 + result.monthsToFire! ~/ 12;
      final amount = money.compact(extraSaving);
      final age = l10n.ageLabel(fireAge);
      final base = baseResult.monthsToFire;
      if (base == null) return l10n.onbWhatIfEffect(amount, age);
      final savedMonths = base - result.monthsToFire!;
      final years = savedMonths ~/ 12;
      final months = savedMonths % 12;
      final shortened = [
        if (years > 0) l10n.yearsLabel(years),
        if (months > 0) l10n.monthsLabel(months),
      ].join(' ');
      return shortened.isEmpty
          ? l10n.onbWhatIfEffect(amount, age)
          : l10n.onbWhatIfEffectShortened(amount, age, shortened);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onbWhatIfTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              effectLabel(),
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: extraSaving.clamp(0, maxExtra).toDouble(),
              min: 0,
              max: maxExtra.toDouble(),
              divisions: 60,
              onChanged: (value) => onChanged(value.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.onbSliderPlus(money.compact(0)),
                    style: theme.textTheme.labelSmall),
                Text(l10n.onbSliderPlus(money.compact(maxExtra)),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSavingView extends StatelessWidget {
  final VoidCallback onAdjustExpense;

  const _NoSavingView({required this.onAdjustExpense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.savings_outlined,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.onbNoSavingTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onbNoSavingBody,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAdjustExpense,
                  child: Text(l10n.onbAdjustExpense),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssumptionRow extends StatelessWidget {
  final String label;
  final String value;

  const _AssumptionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium!
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
