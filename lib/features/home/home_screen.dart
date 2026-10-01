import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ym.dart';
import '../../data/db/database.dart';
import '../../data/db/providers.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_store.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../simulation/chart_axis.dart';
import '../common/deviation_badge.dart';
import '../common/milestone_labels.dart';
import '../common/money.dart';
import '../goal/goal_settings_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../settings/settings_screen.dart';
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
          Scaffold(body: Center(child: Text(context.l10n.errorGeneric('$error')))),
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
            Text(context.l10n.homeNoPlan),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(OnboardingScreen.path),
              child: Text(context.l10n.homeCreatePlan),
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final summaries =
        ref.watch(snapshotSummariesProvider).value ?? const <SnapshotSummary>[];
    final masked = ref.watch(maskAmountsProvider).value ?? false;
    final revisions =
        ref.watch(activePlanRevisionsProvider).value ?? const <Plan>[];

    final input = planInputOf(plan);
    final result = solvePlan(input);
    final currentYm = nowYm();
    final monthsElapsed = math.max(0, ymDiffMonths(plan.startedYm, currentYm));
    final latest = summaries.isEmpty ? null : summaries.last;
    final currentAssets = latest?.netWorth ?? plan.currentAssets;
    final hasCurrentMonthRecord = summaries.any((s) => s.ym == currentYm);
    final monthsSinceLast =
        latest == null ? null : ymDiffMonths(latest.ym, currentYm);

    // 마일스톤 배너 — 최신 기록 월에 달성한 것이 있을 때만 (PRD S3)
    final milestones =
        ref.watch(milestonesProvider).value ?? const <Milestone>[];
    final latestMilestones = latest == null
        ? const <Milestone>[]
        : [
            for (final milestone in milestones)
              if (milestone.achievedYm == latest.ym) milestone,
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeGoalSettingsTooltip,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(GoalSettingsScreen.path),
          ),
          // 금액 가림 토글 — 탭 1번 (지하철에서 여는 앱)
          IconButton(
            tooltip: masked ? l10n.homeShowAmounts : l10n.homeHideAmounts,
            icon: Icon(masked ? Icons.visibility_off : Icons.visibility),
            onPressed: () => ref
                .read(settingsStoreProvider)
                .set(SettingKeys.maskAmounts, !masked),
          ),
          IconButton(
            tooltip: l10n.homeSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(SettingsScreen.path),
          ),
        ],
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
            if (latestMilestones.isNotEmpty)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Text('🏆', style: TextStyle(fontSize: 24)),
                  title: Text(
                    milestoneLabel(l10n, money.currency,
                        latestMilestones.last.milestoneKey),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: latestMilestones.length > 1
                      ? Text(l10n.homeMoreMilestones(latestMilestones.length - 1))
                      : null,
                ),
              ),
            _DdayCard(
              result: result,
              monthsElapsed: monthsElapsed,
              currentAssets: currentAssets,
              masked: masked,
              money: money,
            ),
            const SizedBox(height: 12),
            _TrajectoryCard(
              plan: plan,
              input: input,
              result: result,
              summaries: summaries,
              masked: masked,
              revisions: revisions,
              money: money,
            ),
            const SizedBox(height: 12),
            _SavingRateCard(summaries: summaries),
            if (summaries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PastRecordsCard(
                  summaries: summaries, masked: masked, money: money),
            ],
            if (hasCurrentMonthRecord) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  l10n.homeRecordedThisMonth,
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

/// 지난 기록 목록 — 탭하면 그 월 스냅샷 수정 화면으로 (S3 → S5 소급 편집)
class _PastRecordsCard extends StatelessWidget {
  final List<SnapshotSummary> summaries;
  final bool masked;
  final MoneyFormat money;

  const _PastRecordsCard({
    required this.summaries,
    required this.masked,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final items = [...summaries]
      ..sort((a, b) => b.snapshot.ym.compareTo(a.snapshot.ym));
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l10n.homePastRecords, style: theme.textTheme.titleMedium),
          ),
          for (final s in items)
            ListTile(
              key: ValueKey('record-${s.snapshot.ym}'),
              title: Text(
                  formatYm(s.snapshot.ym, languageCode: languageCode)),
              subtitle: Text(l10n.homeTapToEdit),
              trailing: Text(
                _money(l10n, money, s.netWorth, masked),
                style: theme.textTheme.titleSmall,
              ),
              onTap: () => context
                  .push('${SnapshotFlowScreen.path}?ym=${s.snapshot.ym}'),
            ),
        ],
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
    final l10n = context.l10n;
    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // 복귀 유저에게 비난 톤 금지 (PRD S3, US8)
        title: Text(
          isComeback
              ? l10n.homeComeback
              : l10n.homeRecordPrompt('${currentYm % 100}'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.homeRecordSubtitle),
        trailing: FilledButton(
          onPressed: () => context.push(SnapshotFlowScreen.path),
          child: Text(l10n.homeRecordButton),
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
  final MoneyFormat money;

  const _DdayCard({
    required this.result,
    required this.monthsElapsed,
    required this.currentAssets,
    required this.masked,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final progress = result.fireNumber <= 0
        ? 0.0
        : (currentAssets / result.fireNumber).clamp(0.0, 1.0);

    final String headline;
    final months = result.monthsToFire;
    if (months == null) {
      headline = l10n.homeUnreachable;
    } else {
      final remaining = math.max(0, months - monthsElapsed);
      if (remaining == 0 || currentAssets >= result.fireNumber) {
        headline = l10n.homeReached;
      } else {
        final years = remaining ~/ 12;
        final remainMonths = remaining % 12;
        headline = years == 0
            ? l10n.homeUntilFireMonths(remainMonths)
            : l10n.homeUntilFireYearsMonths(years, remainMonths);
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
              l10n.homeFireProgress(
                (progress * 100).toStringAsFixed(0),
                _money(l10n, money, currentAssets, masked),
                _money(l10n, money, result.fireNumber, masked),
              ),
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
  final List<Plan> revisions;
  final MoneyFormat money;

  const _TrajectoryCard({
    required this.plan,
    required this.input,
    required this.result,
    required this.summaries,
    required this.masked,
    required this.revisions,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.homeTrajectory, style: theme.textTheme.titleMedium),
                const Spacer(),
                if (summaries.length >= 2)
                  DeviationBadge(
                    plan: plan,
                    result: result,
                    actualAssets: summaries.last.netWorth,
                    atYm: summaries.last.ym,
                  ),
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
                    ? l10n.homeFirstRecordHint
                    : l10n.homeSecondRecordHint,
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

  double _revisionX(Plan revision) {
    final revisionYm =
        ymOf(DateTime.fromMillisecondsSinceEpoch(revision.createdAt));
    return ymDiffMonths(plan.startedYm, revisionYm) / 12;
  }

  Widget _chart(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final trajectory = result.assetsByMonth;
    // 세로축 단위는 시뮬레이션 차트와 동일 (KRW·JPY 1억 / USD $100K)
    final axisUnit = chartAmountUnit(money.currency);

    final planSpots = <FlSpot>[
      for (var m = 0; m < trajectory.length; m += 12)
        FlSpot(m / 12, trajectory[m] / axisUnit),
      FlSpot((trajectory.length - 1) / 12, trajectory.last / axisUnit),
    ];

    final actualSpots = <FlSpot>[
      for (final summary in summaries)
        if (ymDiffMonths(plan.startedYm, summary.ym) >= 0)
          FlSpot(
            ymDiffMonths(plan.startedYm, summary.ym) / 12,
            summary.netWorth / axisUnit,
          ),
    ];

    // 계획 변경 마커 (S7 수용 기준): 리비전 시점을 수직선으로 표시
    final maxX = (trajectory.length - 1) / 12;
    final revisionLines = <VerticalLine>[
      for (final revision in revisions.skip(1))
        if (_revisionX(revision) > 0 && _revisionX(revision) < maxX)
          VerticalLine(
            x: _revisionX(revision),
            color: theme.colorScheme.tertiary,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
    ];

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          extraLinesData: ExtraLinesData(verticalLines: revisionLines),
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
                getTitlesWidget: (value, meta) {
                  // 끝점 라벨은 마지막 눈금과 겹치므로 생략 (fl_chart가 max에 별도로 그림)
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    chartAmountLabel(money, value, axisUnit),
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
                    '${input.age0 + value.toInt()}${l10n.ageSuffix}',
                    style: theme.textTheme.labelSmall,
                  );
                },
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
    final l10n = context.l10n;

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
              Text(l10n.homeSavingRate, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                l10n.homeSavingRateHint,
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
                Text(l10n.homeSavingRateThisMonth,
                    style: theme.textTheme.titleMedium),
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
                      Text(l10n.homeMonthShort('${entry.ym % 100}'),
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

String _money(AppLocalizations l10n, MoneyFormat money, int minor, bool masked) =>
    masked ? l10n.commonMasked : money.compact(minor);
