import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';

/// 몬테카를로 상세 분포 (S4 유료 본체)
///
/// 기대수명 시점 자산 분포 밴드(p10/p50/p90)와 자산 고갈 나이 분포.
class MonteCarloDetailScreen extends ConsumerWidget {
  final PlanInput plan;
  final MonteCarloResult result;

  const MonteCarloDetailScreen({
    super.key,
    required this.plan,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final successPercent = (result.successRate * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mcTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.mcHeadline(successPercent),
              style: theme.textTheme.headlineMedium!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.mcSummary(
                  result.runs, result.successes, plan.lifeExpectancy),
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mcEndingAssetsTitle,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _PercentileRow(
                      label: l10n.mcP10,
                      value: money.compact(result.endingAssetsPercentile(0.1)),
                    ),
                    _PercentileRow(
                      label: l10n.mcP50,
                      value: money.compact(result.endingAssetsPercentile(0.5)),
                      emphasized: true,
                    ),
                    _PercentileRow(
                      label: l10n.mcP90,
                      value: money.compact(result.endingAssetsPercentile(0.9)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mcDepletionTitle,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    if (result.depletionMonths.isEmpty)
                      Text(
                        l10n.mcNoDepletion(plan.lifeExpectancy),
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      _DepletionHistogram(plan: plan, result: result),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.disclaimerSimulation,
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

class _PercentileRow extends StatelessWidget {
  final String label;

  /// 이미 통화 표기로 만든 금액 문자열
  final String value;
  final bool emphasized;

  const _PercentileRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: (emphasized
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium)!
                .copyWith(
              fontWeight: FontWeight.w600,
              color: emphasized ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepletionHistogram extends StatelessWidget {
  final PlanInput plan;
  final MonteCarloResult result;

  const _DepletionHistogram({required this.plan, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 고갈 나이를 5세 단위 버킷으로 (R2: 나이 = age0 + t ~/ 12)
    final buckets = <int, int>{};
    for (final month in result.depletionMonths) {
      final age = plan.age0 + month ~/ 12;
      final bucket = (age ~/ 5) * 5;
      buckets[bucket] = (buckets[bucket] ?? 0) + 1;
    }
    final keys = buckets.keys.toList()..sort();
    final maxCount = buckets.values.fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: maxCount * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= keys.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(context.l10n.simAxisAge(keys[index]),
                      style: theme.textTheme.labelSmall);
                },
              ),
            ),
          ),
          barGroups: [
            for (final (index, bucket) in keys.indexed)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: buckets[bucket]!.toDouble(),
                    color: theme.colorScheme.error.withValues(alpha: 0.75),
                    width: 16,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
