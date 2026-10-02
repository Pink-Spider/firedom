import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/providers.dart';
import '../../data/entitlements.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';
import '../paywall/paywall_sheet.dart';
import 'chart_axis.dart';
import 'scenario_compare_screen.dart';
import 'monte_carlo_detail_screen.dart';
import 'monte_carlo_runner.dart';
import 'portfolio_screen.dart';

/// S4. 시뮬레이션 — What-if 놀이터 (PRD)
///
/// 무료: 결정론 차트 + 슬라이더 3종 + 시나리오 저장 1개.
/// 유료 훅: 몬테카를로 성공 확률 티저 1줄(정확한 값), 상세 분포는 🔒.
/// 여기서 바꾼 가정은 저장 전까지 목표(계획)에 반영되지 않는다.
class SimulationScreen extends ConsumerStatefulWidget {
  static const path = '/simulation';

  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  int? _age0;
  int? _currentAssets;
  int? _monthlySaving;
  int? _returnBp;
  int? _monthlySpend;

  /// 포트폴리오 구성(S4-2)에서 반영된 변동성 — null이면 계획 값 사용
  int? _volatilityBp;
  MonteCarloResult? _mcResult;
  bool _mcRunning = false;
  List<ScenarioEntry> _scenarios = const [];
  bool get _hasScenario => _scenarios.isNotEmpty;

  /// 기대수익률(실질) 슬라이더 상한 (bp) — 놀이터라 공격적 시나리오까지 허용.
  /// 0.25%(25bp) 스텝 유지.
  static const _returnMaxBp = 1500;

  /// 슬라이더 범위는 통화에 맞춘다 ([Currency.monthlyStep] 기준, KRW 10만원).
  /// 월 저축 0 ~ 100칸, 은퇴 후 생활비 5 ~ 100칸.
  /// 현재 순자산 스텝 = 100칸(KRW 1천만원), 기본 상한 30,000칸(KRW 30억)
  static int _monthlyMax(int step) => 100 * step;
  static int _spendMin(int step) => 5 * step;
  static int _assetsStep(int step) => 100 * step;
  static int _assetsMaxDefault(int step) => 30000 * step;

  static int _assetsMaxFor(PlanInput baseline, int step) {
    final assetsStep = _assetsStep(step);
    final maxDefault = _assetsMaxDefault(step);
    return baseline.currentAssets <= maxDefault
        ? maxDefault
        : (baseline.currentAssets / assetsStep).ceil() * assetsStep;
  }

  @override
  void initState() {
    super.initState();
    ref.read(scenarioRepositoryProvider).list().then((list) {
      if (mounted) setState(() => _scenarios = list);
    });
  }

  void _invalidateMc() => _mcResult = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = ref.watch(activePlanRowProvider).value;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.simTitle)),
        body: Center(child: Text(l10n.needPlanFirst)),
      );
    }

    final money = moneyFormatOf(context, ref);
    final step = currencyOf(ref).monthlyStep;
    final baseline = planInputOf(plan);
    final ageMin = baseline.age0 < 19 ? baseline.age0 : 19;
    final ageMax = baseline.lifeExpectancy - 1;
    final assetsMax = _assetsMaxFor(baseline, step);
    _age0 ??= baseline.age0.clamp(ageMin, ageMax);
    _currentAssets ??= baseline.currentAssets.clamp(0, assetsMax);
    _monthlySaving ??= baseline.monthlySaving.clamp(0, _monthlyMax(step));
    _returnBp ??= baseline.realReturnBp.clamp(0, _returnMaxBp);
    _monthlySpend ??=
        baseline.monthlySpendRetire.clamp(_spendMin(step), _monthlyMax(step));

    final input = baseline.copyWith(
      age0: _age0,
      currentAssets: _currentAssets,
      monthlySaving: _monthlySaving,
      realReturnBp: _returnBp,
      monthlySpendRetire: _monthlySpend,
      volatilityBp: _volatilityBp,
    );
    final result = solvePlan(input);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.simTitle),
        actions: [
          IconButton(
            tooltip: l10n.simResetTooltip,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(() {
              _age0 = null;
              _currentAssets = null;
              _monthlySaving = null;
              _returnBp = null;
              _monthlySpend = null;
              _volatilityBp = null;
              _invalidateMc();
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.simIntro,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _ResultHeadline(input: input, result: result),
            if (result.isReachable && result.monthsToFire! > 0) ...[
              const SizedBox(height: 12),
              _SimChart(result: result, age0: input.age0),
            ],
            const SizedBox(height: 12),
            _SliderCard(
              sliderKey: const ValueKey('age-slider'),
              title: l10n.simSliderAge,
              valueLabel: l10n.ageLabel(_age0!),
              value: _age0!.toDouble(),
              min: ageMin.toDouble(),
              max: ageMax.toDouble(),
              divisions: ageMax - ageMin,
              onChanged: (value) => setState(() {
                _age0 = value.round();
                _invalidateMc();
              }),
            ),
            _SliderCard(
              sliderKey: const ValueKey('assets-slider'),
              title: l10n.simSliderAssets,
              valueLabel: money.compact(_currentAssets!),
              value: _currentAssets!.toDouble(),
              min: 0,
              max: assetsMax.toDouble(),
              divisions: assetsMax ~/ _assetsStep(step),
              onChanged: (value) => setState(() {
                _currentAssets = value.round();
                _invalidateMc();
              }),
            ),
            _SliderCard(
              sliderKey: const ValueKey('saving-slider'),
              title: l10n.simSliderSaving,
              valueLabel: money.compact(_monthlySaving!),
              value: _monthlySaving!.toDouble(),
              min: 0,
              max: _monthlyMax(step).toDouble(),
              divisions: 100,
              onChanged: (value) => setState(() {
                _monthlySaving = value.round();
                _invalidateMc();
              }),
            ),
            _SliderCard(
              sliderKey: const ValueKey('return-slider'),
              title: l10n.simSliderReturn,
              valueLabel: '${(_returnBp! / 100).toStringAsFixed(2)}%',
              value: _returnBp!.toDouble(),
              min: 0,
              max: _returnMaxBp.toDouble(),
              divisions: _returnMaxBp ~/ 25,
              onChanged: (value) => setState(() {
                _returnBp = value.round();
                _volatilityBp = null; // 직접 조정 시 포트폴리오 축약 해제
                _invalidateMc();
              }),
              footer: TextButton.icon(
                onPressed: () => _openPortfolio(input),
                icon: const Icon(Icons.pie_chart_outline, size: 18),
                label: Text(l10n.simOpenPortfolio),
              ),
            ),
            _SliderCard(
              sliderKey: const ValueKey('spend-slider'),
              title: l10n.simSliderSpend,
              valueLabel: money.compact(_monthlySpend!),
              value: _monthlySpend!.toDouble(),
              min: _spendMin(step).toDouble(),
              max: _monthlyMax(step).toDouble(),
              divisions: 95,
              onChanged: (value) => setState(() {
                _monthlySpend = value.round();
                _invalidateMc();
              }),
            ),
            const SizedBox(height: 4),
            _MonteCarloCard(
              input: input,
              result: result,
              mcResult: _mcResult,
              running: _mcRunning,
              isPremium: ref.watch(isPremiumProvider).value ?? false,
              onRun: () => _runMonteCarlo(input, result),
              onShowDetail: (mc, isPremium) =>
                  _showDetail(input, mc, isPremium),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _saveScenario(input),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(l10n.simSaveScenario),
                ),
                const SizedBox(width: 8),
                if (_hasScenario)
                  TextButton(
                    onPressed: _openScenarios,
                    child: Text(_scenarios.length > 1
                        ? l10n.simLoadScenarioCount(_scenarios.length)
                        : l10n.simLoadScenario),
                  ),
                // 비교는 시나리오가 2개 이상일 때만 의미가 있다.
                // 무료는 1개까지만 저장되므로 자연히 프리미엄 전용이 되지만,
                // 구독 해지 후 기존 시나리오가 남은 경우를 위해 게이트를 명시한다.
                if (_scenarios.length > 1)
                  TextButton(
                    key: const ValueKey('compare-scenarios'),
                    onPressed: _openCompare,
                    child: Text(
                        (ref.watch(isPremiumProvider).value ?? false)
                            ? l10n.simCompare
                            : l10n.simCompareLocked),
                  ),
              ],
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

  /// S4-2 포트폴리오 구성으로 이동 — 반환된 축약 값(가중 수익률·변동성)을
  /// 슬라이더/몬테카를로에 반영한다 (계획에는 반영 안 됨, A5 원칙 동일)
  Future<void> _openPortfolio(PlanInput input) async {
    final applied = await Navigator.of(context, rootNavigator: true)
        .push<PortfolioApplyResult>(
      MaterialPageRoute(builder: (_) => PortfolioScreen(base: input)),
    );
    if (applied == null || !mounted) return;
    setState(() {
      _returnBp = applied.returnBp.clamp(0, _returnMaxBp);
      _volatilityBp = applied.volatilityBp;
      _invalidateMc();
    });
  }

  void _showDetail(PlanInput input, MonteCarloResult mc, bool isPremium) {
    if (!isPremium) {
      // 유료 훅 (PRD S4): 티저는 무료, 상세 분포는 구독
      showPaywallSheet(context, successRate: mc.successRate);
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => MonteCarloDetailScreen(plan: input, result: mc),
      ),
    );
  }

  Future<void> _runMonteCarlo(PlanInput input, FireResult result) async {
    final retirementMonth =
        result.monthsToFire ?? math.min(maxSimulationMonths, input.lifeMonths);
    setState(() => _mcRunning = true);
    final request = MonteCarloRequest(
      plan: input,
      retirementMonth: retirementMonth,
    );
    final mc = await ref.read(monteCarloRunnerProvider)(request);
    if (!mounted) return;
    setState(() {
      _mcResult = mc;
      _mcRunning = false;
    });
  }

  Future<void> _reloadScenarios() async {
    final list = await ref.read(scenarioRepositoryProvider).list();
    if (mounted) setState(() => _scenarios = list);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveScenario(PlanInput input) async {
    final l10n = context.l10n;
    final isPremium = ref.read(isPremiumProvider).value ?? false;
    var name = l10n.simDefaultScenarioName;
    if (isPremium) {
      final hint = l10n.simScenarioNameHint(_scenarios.length + 1);
      final entered = await _askScenarioName(hint);
      if (entered == null) return; // 취소
      name = entered.trim().isEmpty ? hint : entered.trim();
    }
    await ref
        .read(scenarioRepositoryProvider)
        .save(name: name, input: input, keepExisting: isPremium);
    await _reloadScenarios();
    _snack(isPremium
        ? l10n.simScenarioSaved(name)
        : l10n.simScenarioSavedFree);
  }

  /// 프리미엄 저장 시 이름 입력
  Future<String?> _askScenarioName(String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.simScenarioNameTitle),
        content: TextField(
          key: const ValueKey('scenario-name'),
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  /// 시나리오 나란히 비교 (프리미엄). 무료는 페이월로 안내한다.
  void _openCompare() {
    if (!(ref.read(isPremiumProvider).value ?? false)) {
      showPaywallSheet(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ScenarioCompareSheet(scenarios: _scenarios),
    );
  }

  /// 저장된 시나리오 목록 — 탭해서 불러오기, 삭제 가능
  void _openScenarios() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: _scenarios.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(sheetContext.l10n.simNoScenarios),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final s in _scenarios)
                      ListTile(
                        key: ValueKey('scenario-${s.id}'),
                        title: Text(s.name),
                        subtitle: Text(_summaryOf(sheetContext, s.input)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: sheetContext.l10n.commonDelete,
                          onPressed: () async {
                            await ref
                                .read(scenarioRepositoryProvider)
                                .delete(s.id);
                            await _reloadScenarios();
                            setSheet(() {});
                            if (_scenarios.isEmpty && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _applyScenario(s.input);
                          _snack(context.l10n.simScenarioLoaded(s.name));
                        },
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 시나리오 요약 (FIRE 나이) — 목록 부제
  String _summaryOf(BuildContext context, PlanInput s) {
    final l10n = context.l10n;
    final r = solvePlan(s);
    if (r.monthsToFire == null) return l10n.simSummaryUnreachable;
    if (r.monthsToFire == 0) return l10n.simSummaryReached;
    return l10n.simFireAge(s.age0 + r.monthsToFire! ~/ 12);
  }

  /// 시나리오 값을 슬라이더에 반영 (나이·순자산·변동성까지 전부 복원)
  void _applyScenario(PlanInput s) {
    final plan = ref.read(activePlanRowProvider).value;
    final baseline = plan == null ? s : planInputOf(plan);
    final ageMin = baseline.age0 < 19 ? baseline.age0 : 19;
    final ageMax = baseline.lifeExpectancy - 1;
    final step =
        (ref.read(currencyProvider).value ?? Currency.fallback).monthlyStep;
    final assetsMax = _assetsMaxFor(baseline, step);
    setState(() {
      _age0 = s.age0.clamp(ageMin, ageMax);
      _currentAssets = s.currentAssets.clamp(0, assetsMax);
      _monthlySaving = s.monthlySaving.clamp(0, _monthlyMax(step));
      _returnBp = s.realReturnBp.clamp(0, _returnMaxBp);
      _monthlySpend =
          s.monthlySpendRetire.clamp(_spendMin(step), _monthlyMax(step));
      _volatilityBp = s.volatilityBp;
      _invalidateMc();
    });
  }
}

class _ResultHeadline extends ConsumerWidget {
  final PlanInput input;
  final FireResult result;

  const _ResultHeadline({required this.input, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final months = result.monthsToFire;

    final String headline;
    if (months == null) {
      headline = l10n.simHeadlineUnreachable;
    } else if (months == 0) {
      headline = l10n.simHeadlineReached;
    } else {
      headline = l10n.simFireAge(input.age0 + months ~/ 12);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (months != null && months > 0)
              Text(
                l10n.simHeadlineDetail(
                  l10n.yearsMonthsLabel(months ~/ 12, months % 12),
                  money.compact(result.fireNumber),
                ),
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final Key sliderKey;
  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  /// 슬라이더 아래 부가 액션 (예: S4-2 포트폴리오 진입 링크)
  final Widget? footer;

  const _SliderCard({
    required this.sliderKey,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  valueLabel,
                  style: theme.textTheme.titleSmall!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              key: sliderKey,
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
            if (footer != null)
              Align(alignment: Alignment.centerLeft, child: footer),
          ],
        ),
      ),
    );
  }
}

class _MonteCarloCard extends StatelessWidget {
  final PlanInput input;
  final FireResult result;
  final MonteCarloResult? mcResult;
  final bool running;
  final bool isPremium;
  final VoidCallback onRun;
  final void Function(MonteCarloResult mc, bool isPremium) onShowDetail;

  const _MonteCarloCard({
    required this.input,
    required this.result,
    required this.mcResult,
    required this.running,
    required this.isPremium,
    required this.onRun,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final mc = mcResult;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.simMcTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (running) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(l10n.simMcRunning, style: theme.textTheme.bodySmall),
            ] else if (mc != null) ...[
              // 티저는 무료에게도 정확한 값 (가짜 블러 금지 — PRD S4)
              Text(
                l10n.simMcSuccess((mc.successRate * 100).toStringAsFixed(0)),
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.simMcCaption(input.lifeExpectancy, mc.runs),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => onShowDetail(mc, isPremium),
                child: Text(
                    isPremium ? l10n.simMcDetail : l10n.simMcDetailLocked),
              ),
            ] else
              FilledButton.tonal(
                onPressed: result.isReachable ? onRun : null,
                child: Text(l10n.simMcRun),
              ),
          ],
        ),
      ),
    );
  }
}

class _SimChart extends ConsumerWidget {
  final FireResult result;
  final int age0;

  const _SimChart({required this.result, required this.age0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final unit = chartAmountUnit(money.currency);
    final trajectory = result.assetsByMonth;
    final spots = <FlSpot>[
      for (var m = 0; m < trajectory.length; m += 12)
        FlSpot(m / 12, trajectory[m] / unit),
      FlSpot((trajectory.length - 1) / 12, trajectory.last / unit),
    ];

    return SizedBox(
      height: 160,
      child: LineChart(
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
                  return Text(
                    chartAmountLabel(money, value, unit),
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
                    l10n.simAxisAge(age0 + value.toInt()),
                    style: theme.textTheme.labelSmall,
                  );
                },
              ),
            ),
          ),
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
