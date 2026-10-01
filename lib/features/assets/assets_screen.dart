import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ym.dart';
import '../../data/db/providers.dart';
import '../../data/repositories/settings_store.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/asset_class_labels.dart';
import '../common/money.dart';

enum _AssetsTab { allocation, cashflow }

/// S6. 자산 뷰 — 다중 관점 (PRD)
///
/// 자산배분(무료): 자산군 도넛 + 목표 배분 대비 편차 — 사실 표시만,
/// 행동 지시 문구 금지. 현금흐름(무료): 소득−지출=저축 막대 + 저축률.
/// 연금·세제 뷰는 미구현이라 v1.0에서는 탭 자체를 노출하지 않는다.
/// 구현 전까지 잠금·결제 유도를 두지 않는다 (CLAUDE.md: 미출시 기능 광고 금지).
class AssetsScreen extends ConsumerStatefulWidget {
  static const path = '/assets';

  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  _AssetsTab _tab = _AssetsTab.allocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assetsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<_AssetsTab>(
              segments: [
                ButtonSegment(
                    value: _AssetsTab.allocation,
                    label: Text(l10n.assetsAllocationTab)),
                ButtonSegment(
                    value: _AssetsTab.cashflow,
                    label: Text(l10n.assetsCashflowTab)),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
            ),
            const SizedBox(height: 16),
            switch (_tab) {
              _AssetsTab.allocation => const _AllocationView(),
              _AssetsTab.cashflow => const _CashflowView(),
            },
          ],
        ),
      ),
    );
  }
}

// ── 자산배분 ──────────────────────────────────────────────────

class _AllocationView extends ConsumerWidget {
  const _AllocationView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final allocation = ref.watch(latestAllocationProvider).value;
    final target = ref.watch(targetAllocationProvider).value ?? const {};
    final masked = ref.watch(maskAmountsProvider).value ?? false;

    if (allocation == null || allocation.byClass.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            l10n.assetsAllocationEmpty,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final byClass = allocation.byClass;
    final total = byClass.values.fold(0, (a, b) => a + b);
    final classes = byClass.keys.toList()
      ..sort((a, b) => byClass[b]!.compareTo(byClass[a]!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            l10n.assetsAsOf(formatYm(allocation.ym,
                languageCode: Localizations.localeOf(context).languageCode)),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 48,
              sections: [
                for (final assetClass in classes)
                  PieChartSectionData(
                    value: byClass[assetClass]!.toDouble(),
                    color: assetClassColor(assetClass),
                    radius: 40,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final assetClass in classes)
          _AllocationRow(
            assetClass: assetClass,
            amount: byClass[assetClass]!,
            actualPercent: (byClass[assetClass]! * 100 / total).round(),
            targetPercent: target[assetClass],
            masked: masked,
            money: money,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _editTarget(context, ref, classes, target),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(
                target.isEmpty ? l10n.assetsSetTarget : l10n.assetsEditTarget),
          ),
        ),
      ],
    );
  }

  Future<void> _editTarget(
    BuildContext context,
    WidgetRef ref,
    List<String> classes,
    Map<String, int> current,
  ) async {
    final controllers = {
      for (final assetClass in classes)
        assetClass: TextEditingController(
            text: current[assetClass]?.toString() ?? ''),
    };
    final l10n = context.l10n;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assetsTargetDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final assetClass in classes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  key: ValueKey('target-$assetClass'),
                  controller: controllers[assetClass],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: assetClassLabel(l10n, assetClass),
                    suffixText: '%',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (saved != true) return;

    final target = <String, int>{};
    for (final entry in controllers.entries) {
      final value = int.tryParse(entry.value.text.trim());
      if (value != null && value > 0) target[entry.key] = value;
    }
    await ref
        .read(settingsStoreProvider)
        .set(SettingKeys.targetAllocation, target);
  }
}

class _AllocationRow extends StatelessWidget {
  final String assetClass;
  final int amount;
  final int actualPercent;
  final int? targetPercent;
  final bool masked;
  final MoneyFormat money;

  const _AllocationRow({
    required this.assetClass,
    required this.amount,
    required this.actualPercent,
    required this.targetPercent,
    required this.masked,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final target = targetPercent;
    // 사실 표시만 — "리밸런싱하세요" 같은 행동 지시 금지 (제품 원칙)
    final String? deviationLabel;
    if (target == null) {
      deviationLabel = null;
    } else {
      final deviation = actualPercent - target;
      deviationLabel = deviation == 0
          ? l10n.assetsTargetMatch(target)
          : l10n.assetsTargetDeviation(
              target, '${deviation > 0 ? '+' : '−'}${deviation.abs()}');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: assetClassColor(assetClass),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assetClassLabel(l10n, assetClass),
                    style: theme.textTheme.bodyLarge),
                if (deviationLabel != null)
                  Text(
                    deviationLabel,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$actualPercent%',
                  style: theme.textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(
                masked ? l10n.commonMasked : money.compact(amount),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 현금흐름 ──────────────────────────────────────────────────

class _CashflowView extends ConsumerWidget {
  const _CashflowView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final summaries =
        ref.watch(snapshotSummariesProvider).value ?? const <SnapshotSummary>[];

    final withFlow = [
      for (final summary in summaries)
        if (summary.snapshot.income != null &&
            summary.snapshot.expense != null)
          summary,
    ];

    if (withFlow.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            l10n.assetsCashflowEmpty,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final recent = withFlow.length <= 6
        ? withFlow
        : withFlow.sublist(withFlow.length - 6);
    final maxValue = [
      for (final s in recent) ...[s.snapshot.income!, s.snapshot.expense!],
    ].fold(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(
                color: theme.colorScheme.primary, label: l10n.assetsIncome),
            const SizedBox(width: 12),
            _LegendDot(
                color: theme.colorScheme.outline, label: l10n.snapExpense),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxValue * 1.2 / 1000000,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= recent.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                          l10n.homeMonthShort('${recent[index].ym % 100}'),
                          style: theme.textTheme.labelSmall);
                    },
                  ),
                ),
              ),
              barGroups: [
                for (final (index, summary) in recent.indexed)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: summary.snapshot.income! / 1000000,
                        color: theme.colorScheme.primary,
                        width: 10,
                      ),
                      BarChartRodData(
                        toY: summary.snapshot.expense! / 1000000,
                        color: theme.colorScheme.outline,
                        width: 10,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final summary in recent.reversed)
          _CashflowRow(summary: summary, money: money),
      ],
    );
  }
}

class _CashflowRow extends StatelessWidget {
  final SnapshotSummary summary;
  final MoneyFormat money;

  const _CashflowRow({required this.summary, required this.money});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final income = summary.snapshot.income!;
    final expense = summary.snapshot.expense!;
    final saving = income - expense;
    final rate = savingRate(income: income, expense: expense);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(l10n.homeMonthShort('${summary.ym % 100}'),
              style: theme.textTheme.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.assetsSaving(money.compact(saving)),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            rate == null
                ? l10n.assetsSavingRateNone
                : l10n.assetsSavingRate((rate.clamp(-1.0, 1.0) * 100).round()),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
