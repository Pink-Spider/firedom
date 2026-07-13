import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money_format.dart';
import '../../data/db/providers.dart';
import '../../data/entitlements.dart';
import '../../data/repositories/plan_repository.dart';
import '../../engine/engine.dart';
import '../paywall/paywall_sheet.dart';
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
  int? _monthlySaving;
  int? _returnBp;
  int? _monthlySpend;

  /// 포트폴리오 구성(S4-2)에서 반영된 변동성 — null이면 계획 값 사용
  int? _volatilityBp;
  MonteCarloResult? _mcResult;
  bool _mcRunning = false;
  bool _hasScenario = false;

  /// 기대수익률(실질) 슬라이더 상한 (bp) — 놀이터라 공격적 시나리오까지 허용.
  /// 0.25%(25bp) 스텝 유지.
  static const _returnMaxBp = 1500;

  @override
  void initState() {
    super.initState();
    ref.read(scenarioRepositoryProvider).loadSingle().then((scenario) {
      if (mounted) setState(() => _hasScenario = scenario != null);
    });
  }

  void _invalidateMc() => _mcResult = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = ref.watch(activePlanRowProvider).value;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('시뮬레이션')),
        body: const Center(child: Text('먼저 홈에서 계획을 만들어 주세요')),
      );
    }

    final baseline = planInputOf(plan);
    _monthlySaving ??= baseline.monthlySaving.clamp(0, 10000000);
    _returnBp ??= baseline.realReturnBp.clamp(0, _returnMaxBp);
    _monthlySpend ??= baseline.monthlySpendRetire.clamp(500000, 10000000);

    final input = baseline.copyWith(
      monthlySaving: _monthlySaving,
      realReturnBp: _returnBp,
      monthlySpendRetire: _monthlySpend,
      volatilityBp: _volatilityBp,
    );
    final result = solvePlan(input);

    return Scaffold(
      appBar: AppBar(
        title: const Text('시뮬레이션'),
        actions: [
          IconButton(
            tooltip: '계획 값으로 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(() {
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
              '여기서 바꾼 가정은 계획에 반영되지 않아요 — 마음껏 실험해보세요',
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
              sliderKey: const ValueKey('saving-slider'),
              title: '월 저축액',
              valueLabel: '${formatKoreanMoney(_monthlySaving!)}원',
              value: _monthlySaving!.toDouble(),
              min: 0,
              max: 10000000,
              divisions: 100,
              onChanged: (value) => setState(() {
                _monthlySaving = value.round();
                _invalidateMc();
              }),
            ),
            _SliderCard(
              sliderKey: const ValueKey('return-slider'),
              title: '기대수익률 (실질, 연)',
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
                label: const Text('포트폴리오로 구성하기'),
              ),
            ),
            _SliderCard(
              sliderKey: const ValueKey('spend-slider'),
              title: '은퇴 후 월 생활비',
              valueLabel: '${formatKoreanMoney(_monthlySpend!)}원',
              value: _monthlySpend!.toDouble(),
              min: 500000,
              max: 10000000,
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
                  label: const Text('시나리오 저장'),
                ),
                const SizedBox(width: 8),
                if (_hasScenario)
                  TextButton(
                    onPressed: _loadScenario,
                    child: const Text('불러오기'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '본 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다.',
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

  Future<void> _saveScenario(PlanInput input) async {
    await ref.read(scenarioRepositoryProvider).saveSingle(
          name: '내 시나리오',
          input: input,
        );
    if (!mounted) return;
    setState(() => _hasScenario = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('시나리오를 저장했어요 (무료는 1개까지)')),
    );
  }

  Future<void> _loadScenario() async {
    final scenario = await ref.read(scenarioRepositoryProvider).loadSingle();
    if (scenario == null || !mounted) return;
    setState(() {
      _monthlySaving = scenario.input.monthlySaving.clamp(0, 10000000);
      _returnBp = scenario.input.realReturnBp.clamp(0, _returnMaxBp);
      _monthlySpend =
          scenario.input.monthlySpendRetire.clamp(500000, 10000000);
      _invalidateMc();
    });
  }
}

class _ResultHeadline extends StatelessWidget {
  final PlanInput input;
  final FireResult result;

  const _ResultHeadline({required this.input, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = result.monthsToFire;

    final String headline;
    if (months == null) {
      headline = '100년 안에 도달이 어려워요';
    } else if (months == 0) {
      headline = '이미 FIRE 도달!';
    } else {
      headline = 'FIRE 나이 ${input.age0 + months ~/ 12}세';
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
                '${months ~/ 12}년 ${months % 12}개월 후 · '
                '필요 자산 ${formatKoreanMoney(result.fireNumber)}원',
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
    final mc = mcResult;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시장 변동성 속에서도 성공할까?',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (running) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                '5,000가지 시장 시나리오를 계산하고 있어요…',
                style: theme.textTheme.bodySmall,
              ),
            ] else if (mc != null) ...[
              // 티저는 무료에게도 정확한 값 (가짜 블러 금지 — PRD S4)
              Text(
                '이 계획의 성공 확률 ${(mc.successRate * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '기대수명 ${input.lifeExpectancy}세까지 자산이 남아있을 확률 · '
                '${mc.runs}회 시뮬레이션',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => onShowDetail(mc, isPremium),
                child: Text(isPremium ? '상세 분포 보기' : '상세 분포 보기 🔒'),
              ),
            ] else
              FilledButton.tonal(
                onPressed: result.isReachable ? onRun : null,
                child: const Text('성공 확률 계산하기'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SimChart extends StatelessWidget {
  final FireResult result;
  final int age0;

  const _SimChart({required this.result, required this.age0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trajectory = result.assetsByMonth;
    final spots = <FlSpot>[
      for (var m = 0; m < trajectory.length; m += 12)
        FlSpot(m / 12, trajectory[m] / 100000000),
      FlSpot((trajectory.length - 1) / 12, trajectory.last / 100000000),
    ];

    return SizedBox(
      height: 160,
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
