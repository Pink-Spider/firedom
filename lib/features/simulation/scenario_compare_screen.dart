import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/scenario_repository.dart';
import '../../engine/engine.dart';
import '../../core/money_format.dart';

/// S4. 시나리오 나란히 비교 (프리미엄)
///
/// 저장된 시나리오 2개를 골라 FIRE 나이·필요 자산·월 저축액과 궤도를
/// 나란히 놓고 본다. 엔진(`solvePlan`)은 순수 함수라 시나리오마다 그대로
/// 다시 돌린다.
///
/// 사실 표시만 한다 — "A안이 낫다" 같은 행동 지시 문구를 넣지 않는다
/// (CLAUDE.md 제품 원칙: 투자자문 규제).
class ScenarioCompareSheet extends StatefulWidget {
  final List<ScenarioEntry> scenarios;

  const ScenarioCompareSheet({super.key, required this.scenarios});

  @override
  State<ScenarioCompareSheet> createState() => _ScenarioCompareSheetState();
}

class _ScenarioCompareSheetState extends State<ScenarioCompareSheet> {
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
    final left = _entry(_leftId);
    final right = _entry(_rightId);
    final leftResult = solvePlan(left.input);
    final rightResult = solvePlan(right.input);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text('시나리오 비교', style: theme.textTheme.titleMedium),
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
          ),
          const SizedBox(height: 20),
          Text('궤도', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _CompareChart(
              leftInput: left.input,
              rightInput: right.input,
              leftResult: leftResult,
              rightResult: rightResult,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '정보 제공 목적이며 투자 자문이 아닙니다.',
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

  const _CompareTable({
    required this.left,
    required this.right,
    required this.leftResult,
    required this.rightResult,
  });

  String _fireAge(ScenarioEntry e, FireResult r) {
    final months = r.monthsToFire;
    if (months == null) return '도달 어려움';
    if (months == 0) return '이미 도달';
    return '${e.input.age0 + months ~/ 12}세';
  }

  /// FIRE 나이 차이 — 사실만 표시하고 우열은 판단하지 않는다.
  String? _gapText() {
    final a = leftResult.monthsToFire;
    final b = rightResult.monthsToFire;
    if (a == null || b == null) return null;
    final ageA = left.input.age0 + a ~/ 12;
    final ageB = right.input.age0 + b ~/ 12;
    final diff = (ageA - ageB).abs();
    if (diff == 0) return 'FIRE 나이가 같아요';
    final earlier = ageA < ageB ? 'A' : 'B';
    return '$earlier가 $diff년 빨라요';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = _gapText();
    return Column(
      children: [
        _row(context, '',
            left.name, right.name, header: true),
        const Divider(height: 1),
        _row(context, 'FIRE 나이',
            _fireAge(left, leftResult), _fireAge(right, rightResult),
            emphasize: true),
        _row(context, '필요 자산',
            formatKoreanMoney(leftResult.fireNumber),
            formatKoreanMoney(rightResult.fireNumber)),
        _row(context, '월 저축액',
            formatKoreanMoney(left.input.monthlySaving),
            formatKoreanMoney(right.input.monthlySaving)),
        _row(context, '기대수익률',
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

  const _CompareChart({
    required this.leftInput,
    required this.rightInput,
    required this.leftResult,
    required this.rightResult,
  });

  /// 연 단위로 다운샘플 — 억 원 단위 y값
  List<FlSpot> _spots(FireResult r) {
    final assets = r.assetsByMonth;
    return [
      for (var m = 0; m < assets.length; m += 12)
        FlSpot(m / 12, assets[m] / 100000000),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age0 = leftInput.age0 < rightInput.age0
        ? leftInput.age0
        : rightInput.age0;
    return LineChart(
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
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                // 끝점 라벨은 마지막 눈금과 겹치므로 생략 (fl_chart가 max에 별도로 그림)
                if (value == meta.max) return const SizedBox.shrink();
                return Text('${value.toInt()}억',
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
                return Text('${age0 + value.toInt()}세',
                    style: theme.textTheme.labelSmall);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots(leftResult),
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: _spots(rightResult),
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
