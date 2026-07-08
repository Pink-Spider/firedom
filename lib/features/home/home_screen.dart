import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import '../../core/ym.dart';
import '../../data/db/database.dart';
import '../../data/db/providers.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_store.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../engine/engine.dart';
import '../onboarding/onboarding_screen.dart';
import '../snapshot/snapshot_flow_screen.dart';

/// S3. 홈 — 궤도 대시보드 (PRD)
///
/// 3초 안에 "나 잘 가고 있나"에 답한다: D-day + 진행률, 궤도 차트(계획 점선
/// vs 실제 점), 편차 배지, 저축률, 기록 유도 카드.
class HomeScreen extends ConsumerWidget {
  static const path = '/';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activePlanRowProvider);
    return planAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('오류가 발생했어요: $error'))),
      data: (plan) =>
          plan == null ? const _EmptyHome() : _Dashboard(plan: plan),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('아직 계획이 없어요'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(OnboardingScreen.path),
              child: const Text('60초 만에 계획 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  final Plan plan;

  const _Dashboard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        ref.watch(snapshotSummariesProvider).value ?? const <SnapshotSummary>[];
    final masked = ref.watch(maskAmountsProvider).value ?? false;

    final input = planInputOf(plan);
    final result = solvePlan(input);
    final currentYm = nowYm();
    final monthsElapsed = math.max(0, ymDiffMonths(plan.startedYm, currentYm));
    final latest = summaries.isEmpty ? null : summaries.last;
    final currentAssets = latest?.netWorth ?? plan.currentAssets;
    final hasCurrentMonthRecord = summaries.any((s) => s.ym == currentYm);
    final monthsSinceLast =
        latest == null ? null : ymDiffMonths(latest.ym, currentYm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('파이어덤'),
        actions: [
          // 금액 가림 토글 — 탭 1번 (지하철에서 여는 앱)
          IconButton(
            tooltip: masked ? '금액 보이기' : '금액 가리기',
            icon: Icon(masked ? Icons.visibility_off : Icons.visibility),
            onPressed: () => ref
                .read(settingsStoreProvider)
                .set(SettingKeys.maskAmounts, !masked),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(SnapshotFlowScreen.path),
        icon: const Icon(Icons.add),
        label: const Text('기록'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            if (!hasCurrentMonthRecord)
              _RecordNudgeCard(
                currentYm: currentYm,
                isComeback: monthsSinceLast != null && monthsSinceLast >= 3,
              ),
            _DdayCard(
              result: result,
              monthsElapsed: monthsElapsed,
              currentAssets: currentAssets,
              masked: masked,
            ),
            const SizedBox(height: 12),
            _TrajectoryCard(
              plan: plan,
              input: input,
              result: result,
              summaries: summaries,
              masked: masked,
            ),
            const SizedBox(height: 12),
            _SavingRateCard(summaries: summaries),
            if (hasCurrentMonthRecord) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '이번 달 기록 완료 — 다음 기록은 다음 달에 만나요',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordNudgeCard extends StatelessWidget {
  final int currentYm;
  final bool isComeback;

  const _RecordNudgeCard({required this.currentYm, required this.isComeback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // 복귀 유저에게 비난 톤 금지 (PRD S3, US8)
        title: Text(
          isComeback
              ? '다시 오셨네요 — 이번 달만 기록하면 돼요'
              : '${currentYm % 100}월 자산을 기록해볼까요?',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('한 달에 3분이면 충분해요'),
        trailing: FilledButton(
          onPressed: () => context.push(SnapshotFlowScreen.path),
          child: const Text('기록하기'),
        ),
      ),
    );
  }
}

class _DdayCard extends StatelessWidget {
  final FireResult result;
  final int monthsElapsed;
  final int currentAssets;
  final bool masked;

  const _DdayCard({
    required this.result,
    required this.monthsElapsed,
    required this.currentAssets,
    required this.masked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = result.fireNumber <= 0
        ? 0.0
        : (currentAssets / result.fireNumber).clamp(0.0, 1.0);

    final String headline;
    final months = result.monthsToFire;
    if (months == null) {
      headline = '현재 가정으로는 도달이 어려워요';
    } else {
      final remaining = math.max(0, months - monthsElapsed);
      if (remaining == 0 || currentAssets >= result.fireNumber) {
        headline = '재정적 자유 목표에 도달했어요!';
      } else {
        final years = remaining ~/ 12;
        final remainMonths = remaining % 12;
        headline = years == 0
            ? '재정적 자유까지 $remainMonths개월'
            : '재정적 자유까지 $years년 $remainMonths개월';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: theme.textTheme.titleLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text(
              'FIRE 진행률 ${(progress * 100).toStringAsFixed(0)}% · '
              '${_money(currentAssets, masked)} / '
              '${_money(result.fireNumber, masked)}',
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

class _TrajectoryCard extends StatelessWidget {
  final Plan plan;
  final PlanInput input;
  final FireResult result;
  final List<SnapshotSummary> summaries;
  final bool masked;

  const _TrajectoryCard({
    required this.plan,
    required this.input,
    required this.result,
    required this.summaries,
    required this.masked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('궤도', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (summaries.length >= 2) _deviationBadge(context),
              ],
            ),
            const SizedBox(height: 12),
            if (result.assetsByMonth.length > 1)
              _chart(context)
            else
              const SizedBox.shrink(),
            if (summaries.length < 2) ...[
              const SizedBox(height: 8),
              Text(
                summaries.isEmpty
                    ? '첫 기록을 남기면 궤도 위에 점이 찍혀요'
                    : '2번째 기록부터 궤도 비교가 시작돼요',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _deviationBadge(BuildContext context) {
    final theme = Theme.of(context);
    final latest = summaries.last;
    final String label;
    Color background = theme.colorScheme.secondaryContainer;
    Color foreground = theme.colorScheme.onSecondaryContainer;

    if (!result.isReachable) {
      label = '가정 점검 필요';
    } else {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: result.assetsByMonth,
        fireNumber: result.fireNumber,
        actualAssets: latest.netWorth,
        monthsElapsed: math.max(0, ymDiffMonths(plan.startedYm, latest.ym)),
      );
      if (deviation == null) {
        label = '이미 목표 도달!';
        background = theme.colorScheme.primary;
        foreground = theme.colorScheme.onPrimary;
      } else {
        final rounded = deviation.round();
        if (rounded >= 1) {
          label = '계획보다 $rounded개월 앞서는 중';
          background = theme.colorScheme.primaryContainer;
          foreground = theme.colorScheme.onPrimaryContainer;
        } else if (rounded <= -1) {
          // 비난 톤 금지 (제품 원칙)
          label = '계획보다 ${-rounded}개월 뒤 — 따라잡을 수 있어요';
        } else {
          label = '계획대로 진행 중';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _chart(BuildContext context) {
    final theme = Theme.of(context);
    final trajectory = result.assetsByMonth;

    final planSpots = <FlSpot>[
      for (var m = 0; m < trajectory.length; m += 12)
        FlSpot(m / 12, trajectory[m] / 100000000),
      FlSpot((trajectory.length - 1) / 12, trajectory.last / 100000000),
    ];

    final actualSpots = <FlSpot>[
      for (final summary in summaries)
        if (ymDiffMonths(plan.startedYm, summary.ym) >= 0)
          FlSpot(
            ymDiffMonths(plan.startedYm, summary.ym) / 12,
            summary.netWorth / 100000000,
          ),
    ];

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                // 가림 모드에서는 금액 축도 숨긴다
                showTitles: !masked,
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
                  '${input.age0 + value.toInt()}세',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
          lineBarsData: [
            // 계획 곡선 (점선)
            LineChartBarData(
              spots: planSpots,
              isCurved: false,
              color: theme.colorScheme.outline,
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
            // 실제 스냅샷 (점)
            if (actualSpots.isNotEmpty)
              LineChartBarData(
                spots: actualSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavingRateCard extends StatelessWidget {
  final List<SnapshotSummary> summaries;

  const _SavingRateCard({required this.summaries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final withRate = [
      for (final summary in summaries)
        if (summary.snapshot.income != null && summary.snapshot.expense != null)
          (
            ym: summary.ym,
            rate: savingRate(
              income: summary.snapshot.income!,
              expense: summary.snapshot.expense!,
            ),
          ),
    ];

    if (withRate.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('저축률', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '기록할 때 소득/지출을 함께 적으면 저축률 추이를 볼 수 있어요',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latestRate = withRate.last.rate;
    final recent = withRate.length <= 6
        ? withRate
        : withRate.sublist(withRate.length - 6);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('이번 달 저축률', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  latestRate == null
                      ? '—'
                      : '${(latestRate.clamp(-1.0, 1.0) * 100).round()}%',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (latestRate ?? 0).clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            // 최근 6개월 미니 추이
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in recent) ...[
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 6 + 40 * (entry.rate ?? 0).clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${entry.ym % 100}월',
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _money(int won, bool masked) =>
    masked ? '●●●' : '${formatKoreanMoney(won)}원';
