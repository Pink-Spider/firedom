import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import '../../data/active_plan_store.dart';
import '../../engine/engine.dart';
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
  /// What-if: 월 추가 저축 (원)
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
    final draft = ref.watch(onboardingDraftProvider);
    if (!draft.isComplete) {
      // 딥링크 등으로 입력 없이 진입한 경우
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('입력이 필요해요 — 돌아가기'),
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
                child: const Text('가정 보기'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _startPlan(plan),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('이 계획 시작하기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPlan(PlanInput plan) async {
    await ref.read(activePlanStoreProvider).save(plan);
    await ref.read(onboardingDraftProvider.notifier).clear();
    ref.invalidate(activePlanProvider);
    if (mounted) context.go(HomeScreen.path);
  }

  void _showAssumptions(BuildContext context, PlanInput plan) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('계산에 사용한 가정',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _AssumptionRow(
              '연 실질수익률',
              '${(plan.realReturnBp / 100).toStringAsFixed(1)}% (중립 프리셋)',
            ),
            _AssumptionRow(
              '안전인출률 (4% 룰)',
              '${(plan.swrBp / 100).toStringAsFixed(1)}%',
            ),
            _AssumptionRow('기대수명', '${plan.lifeExpectancy}세'),
            _AssumptionRow('금액 기준', '모든 금액은 오늘 돈 가치(실질)'),
            _AssumptionRow('은퇴 후 월 생활비', '현재 월 지출과 동일'),
            const SizedBox(height: 16),
            Text(
              '본 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다. '
              '가정은 목표 설정 화면에서 언제든 바꿀 수 있어요.',
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
    final months = monthsToFire;

    if (months == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('지금 조건으로는', style: theme.textTheme.titleMedium),
          Text(
            '100년 안에 도달이 어려워요',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '아래 슬라이더로 저축을 늘리면 얼마나 달라지는지 볼 수 있어요.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (months == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('축하해요!', style: theme.textTheme.titleMedium),
          Text('이미 FIRE에 도달했어요',
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
        Text('당신의 FIRE 나이', style: theme.textTheme.titleMedium),
        Text(
          '$fireAge세',
          style: theme.textTheme.displayLarge!.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          remainMonths == 0 ? '약 $years년 후' : '약 $years년 $remainMonths개월 후',
          style: theme.textTheme.titleMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FireNumberCard extends StatelessWidget {
  final int monthlyExpense;
  final int swrBp;
  final int fireNumber;

  const _FireNumberCard({
    required this.monthlyExpense,
    required this.swrBp,
    required this.fireNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swrPercent = (swrBp / 100).toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('필요 자산 (FIRE Number)',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              '${formatKoreanMoney(fireNumber)}원',
              style: theme.textTheme.headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '월 지출 ${formatKoreanMoney(monthlyExpense)}원 × $swrPercent% 룰 기준',
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

class _TrajectoryChart extends StatelessWidget {
  final FireResult result;
  final int age0;

  const _TrajectoryChart({required this.result, required this.age0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trajectory = result.assetsByMonth;

    // 연 단위로 다운샘플 + 마지막 점(FIRE 도달)
    final spots = <FlSpot>[
      for (var m = 0; m < trajectory.length; m += 12)
        FlSpot(m / 12, trajectory[m] / 100000000),
      FlSpot(
        (trajectory.length - 1) / 12,
        trajectory.last / 100000000,
      ),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
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
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}억',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) => Text(
                  '${age0 + value.toInt()}세',
                  style: theme.textTheme.labelSmall,
                ),
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

class _WhatIfSlider extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String effectLabel() {
      if (extraSaving == 0) return '슬라이더를 움직여 보세요';
      if (result.monthsToFire == null) return '아직 도달이 어려워요';
      final fireAge = age0 + result.monthsToFire! ~/ 12;
      final base = baseResult.monthsToFire;
      if (base == null) return '+${formatKoreanMoney(extraSaving)}원 → $fireAge세';
      final savedMonths = base - result.monthsToFire!;
      final years = savedMonths ~/ 12;
      final months = savedMonths % 12;
      final shortened = [
        if (years > 0) '$years년',
        if (months > 0) '$months개월',
      ].join(' ');
      return shortened.isEmpty
          ? '+${formatKoreanMoney(extraSaving)}원 → $fireAge세'
          : '+${formatKoreanMoney(extraSaving)}원 → $fireAge세 ($shortened 단축)';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('매달 조금 더 저축한다면?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              effectLabel(),
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: extraSaving.toDouble(),
              min: 0,
              max: 3000000,
              divisions: 60, // 5만원 단위
              onChanged: (value) => onChanged(value.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('+0원', style: theme.textTheme.labelSmall),
                Text('+300만원', style: theme.textTheme.labelSmall),
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
                '현재 저축이 없어\nFIRE 나이를 계산할 수 없어요',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                '월 지출이 소득과 같거나 더 커요. 지출을 조금만 줄여도 '
                '계획이 만들어져요.',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAdjustExpense,
                  child: const Text('지출 조정하기'),
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
