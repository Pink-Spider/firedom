import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/scenario_repository.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';
import 'chart_axis.dart';

/// S4. 시나리오 나란히 비교 (프리미엄)
///
/// 저장된 시나리오 2개를 골라 FIRE 나이·필요 자산·월 저축액과 궤도를
/// 나란히 놓고 본다. 엔진(`solvePlan`)은 순수 함수라 시나리오마다 그대로
/// 다시 돌린다.
///
/// 사실 표시만 한다 — "A안이 낫다" 같은 행동 지시 문구를 넣지 않는다
/// (CLAUDE.md 제품 원칙: 투자자문 규제).
class ScenarioCompareSheet extends ConsumerStatefulWidget {
  final List<ScenarioEntry> scenarios;

  const ScenarioCompareSheet({super.key, required this.scenarios});

  @override
  ConsumerState<ScenarioCompareSheet> createState() =>
      _ScenarioCompareSheetState();
}

class _ScenarioCompareSheetState extends ConsumerState<ScenarioCompareSheet> {
  late String _leftId;
  late String _rightId;

  @override
  void initState() {
    super.initState();
    _leftId = widget.scenarios[0].id;
    _rightId = widget.scenarios[1].id;
  }

  ScenarioEntry _entry(String id) =>
      widget.scenarios.firstWhere((s) => s.id == id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final left = _entry(_leftId);
    final right = _entry(_rightId);
    final leftResult = solvePlan(left.input);
    final rightResult = solvePlan(right.input);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text(l10n.cmpTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Picker(
                  label: 'A',
                  color: theme.colorScheme.primary,
                  scenarios: widget.scenarios,
                  selectedId: _leftId,
                  disabledId: _rightId,
                  onChanged: (id) => setState(() => _leftId = id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Picker(
                  label: 'B',
                  color: theme.colorScheme.tertiary,
                  scenarios: widget.scenarios,
                  selectedId: _rightId,
                  disabledId: _leftId,
                  onChanged: (id) => setState(() => _rightId = id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CompareTable(
            left: left,
            right: right,
            leftResult: leftResult,
            rightResult: rightResult,
            money: money,
          ),
          const SizedBox(height: 20),
          Text(l10n.cmpTrajectory, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _CompareChart(
              leftInput: left.input,
              rightInput: right.input,
              leftResult: leftResult,
              rightResult: rightResult,
              money: money,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.disclaimerShort,
            style: theme.textTheme.bodySmall!
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  final String label;
  final Color color;
  final List<ScenarioEntry> scenarios;
  final String selectedId;
  final String disabledId;
  final ValueChanged<String> onChanged;

  const _Picker({
    required this.label,
    required this.color,
    required this.scenarios,
    required this.selectedId,
    required this.disabledId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey('compare-picker-$label'),
          initialValue: selectedId,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final s in scenarios)
              DropdownMenuItem(
                value: s.id,
                enabled: s.id != disabledId,
                child: Text(
                  s.name,
                  overflow: TextOverflow.ellipsis,
                  style: s.id == disabledId
                      ? TextStyle(
                          color: Theme.of(context).disabledColor)
                      : null,
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null && id != disabledId) onChanged(id);
          },
        ),
      ],
    );
  }
}

class _CompareTable extends StatelessWidget {
  final ScenarioEntry left;
  final ScenarioEntry right;
  final FireResult leftResult;
  final FireResult rightResult;
  final MoneyFormat money;

  const _CompareTable({
    required this.left,
    required this.right,
    required this.leftResult,
    required this.rightResult,
    required this.money,
  });

  String _fireAge(AppLocalizations l10n, ScenarioEntry e, FireResult r) {
    final months = r.monthsToFire;
    if (months == null) return l10n.cmpUnreachable;
    if (months == 0) return l10n.cmpReached;
    return l10n.ageLabel(e.input.age0 + months ~/ 12);
  }

  /// FIRE 나이 차이 — 사실만 표시하고 우열은 판단하지 않는다.
  String? _gapText(AppLocalizations l10n) {
    final a = leftResult.monthsToFire;
    final b = rightResult.monthsToFire;
    if (a == null || b == null) return null;
    final ageA = left.input.age0 + a ~/ 12;
    final ageB = right.input.age0 + b ~/ 12;
    final diff = (ageA - ageB).abs();
    if (diff == 0) return l10n.cmpSameAge;
    final earlier = ageA < ageB ? 'A' : 'B';
    return l10n.cmpEarlier(earlier, diff);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final gap = _gapText(l10n);
    return Column(
      children: [
        _row(context, '',
            left.name, right.name, header: true),
        const Divider(height: 1),
        _row(context, l10n.cmpRowFireAge,
            _fireAge(l10n, left, leftResult), _fireAge(l10n, right, rightResult),
            emphasize: true),
        _row(context, l10n.cmpRowFireNumber,
            money.compact(leftResult.fireNumber),
            money.compact(rightResult.fireNumber)),
        _row(context, l10n.simSliderSaving,
            money.compact(left.input.monthlySaving),
            money.compact(right.input.monthlySaving)),
        _row(context, l10n.cmpRowReturn,
            '${(left.input.realReturnBp / 100).toStringAsFixed(1)}%',
            '${(right.input.realReturnBp / 100).toStringAsFixed(1)}%'),
        if (gap != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(gap,
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.primary)),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, String label, String a, String b,
      {bool header = false, bool emphasize = false}) {
    final theme = Theme.of(context);
    final style = header
        ? theme.textTheme.labelMedium
        : emphasize
            ? theme.textTheme.titleSmall
            : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(label,
                style: theme.textTheme.bodySmall!
                    .copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
              child: Text(a, style: style, overflow: TextOverflow.ellipsis)),
          Expanded(
              child: Text(b, style: style, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _CompareChart extends StatelessWidget {
  final PlanInput leftInput;
  final PlanInput rightInput;
  final FireResult leftResult;
  final FireResult rightResult;
  final MoneyFormat money;

  const _CompareChart({
    required this.leftInput,
    required this.rightInput,
    required this.leftResult,
    required this.rightResult,
    required this.money,
  });

  /// 연 단위로 다운샘플 — y값은 통화별 차트 단위([chartAmountUnit])
  List<FlSpot> _spots(FireResult r, int unit) {
    final assets = r.assetsByMonth;
    return [
      for (var m = 0; m < assets.length; m += 12)
        FlSpot(m / 12, assets[m] / unit),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final unit = chartAmountUnit(money.currency);
    final age0 = leftInput.age0 < rightInput.age0
        ? leftInput.age0
        : rightInput.age0;
    return LineChart(
      LineChartData(
        // 축 하한 0 고정 — 자동이면 최솟값 라벨이 눈금 라벨과 겹친다 (home_screen 참고)
        minY: 0,
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
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                // 끝점 라벨은 마지막 눈금과 겹치므로 생략 (fl_chart가 max에 별도로 그림)
                if (value == meta.max) return const SizedBox.shrink();
                return Text(chartAmountLabel(money, value, unit),
                    style: theme.textTheme.labelSmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(l10n.simAxisAge(age0 + value.toInt()),
                    style: theme.textTheme.labelSmall);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(leftResult, unit),
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: _spots(rightResult, unit),
            isCurved: false,
            color: theme.colorScheme.tertiary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
