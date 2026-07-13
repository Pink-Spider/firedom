import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money_format.dart';
import '../../data/entitlements.dart';
import '../../engine/engine.dart';
import '../paywall/paywall_sheet.dart';

/// S4-2 CTA 결과 — S4가 슬라이더/몬테카를로에 반영할 축약 값
class PortfolioApplyResult {
  final int returnBp;
  final int volatilityBp;

  const PortfolioApplyResult({
    required this.returnBp,
    required this.volatilityBp,
  });
}

/// 자산군별 표시 색 (Figma S4-2 팔레트) — 스택 바·색 점·슬라이더에 공통.
/// 엔진(순수 Dart)이 아닌 UI 레이어에만 둔다.
Color assetColor(PortfolioAsset asset) {
  const map = {
    'us_sp500': Color(0xFF9C4A0E),
    'us_nasdaq100': Color(0xFFC4622D),
    'us_dow': Color(0xFFB5651D),
    'kr_equity': Color(0xFFD98A4F),
    'global_dm_em': Color(0xFFE0A96D),
    'us_treasury': Color(0xFF765847),
    'kr_treasury': Color(0xFF9A8271),
    'usd_cash': Color(0xFF5E6B3F),
    'krw_deposit': Color(0xFF85736A),
    'gold': Color(0xFFC9A227),
    'silver': Color(0xFFA8A29E),
    'commodities': Color(0xFF8A7B4F),
    'reits': Color(0xFF6E5A73),
  };
  return map[asset.key] ?? const Color(0xFF9C4A0E);
}

/// S4-2. 시뮬레이션 — 포트폴리오 구성 (PRD, 엔진명세 A11)
///
/// 단일 수익률 가정을 자산군별 비중으로 확장하는 What-if 심화.
/// 무료: 예시 구성 체험(비중 고정). 유료: 비중 자유 편집.
/// 여기서 만든 구성도 계획에는 반영되지 않는다 (S4 놀이터 원칙).
class PortfolioScreen extends ConsumerStatefulWidget {
  /// S4에서 조정 중이던 가정 (저축액·생활비 등은 그대로 쓴다)
  final PlanInput base;

  const PortfolioScreen({super.key, required this.base});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  /// assetKey → weightBp (비중 0 포함 13개 전체)
  late Map<String, int> _weights;
  PortfolioExample? _example;

  /// 비중 슬라이더 스텝 = 250bp(2.5%p). 정규화 단위 50bp와 배수 관계 유지.
  static const _sliderStepBp = 250;

  @override
  void initState() {
    super.initState();
    _applyExample(PortfolioExample.balanced);
  }

  void _applyExample(PortfolioExample example) {
    final built = example.build();
    _weights = {for (final a in PortfolioAsset.values) a.key: 0};
    for (final h in built.holdings) {
      _weights[h.assetKey] = h.weightBp;
    }
    _example = example;
  }

  int get _totalBp => _weights.values.fold(0, (sum, w) => sum + w);

  bool get _isValid => _totalBp == 10000;

  PortfolioInput? get _portfolio {
    if (!_isValid) return null;
    return PortfolioInput(holdings: [
      for (final asset in PortfolioAsset.values)
        if (_weights[asset.key]! > 0)
          PortfolioHolding.fromPreset(asset, weightBp: _weights[asset.key]!),
    ]);
  }

  /// 합계를 정확히 10000bp로 비례 조정 (최대 잔여법, 50bp 단위) —
  /// "자동 정규화 제안"은 UI 책임 (엔진명세 A11)
  void _normalize() {
    final total = _totalBp;
    if (total == 0) return;
    const unit = 50;
    final raw = <String, double>{
      for (final e in _weights.entries) e.key: e.value * 10000 / total,
    };
    final floored = <String, int>{
      for (final e in raw.entries) e.key: (e.value / unit).floor() * unit,
    };
    var remainder = 10000 - floored.values.fold(0, (a, b) => a + b);
    final byFraction = raw.keys.toList()
      ..sort((a, b) =>
          (raw[b]! - floored[b]!).compareTo(raw[a]! - floored[a]!));
    for (final key in byFraction) {
      if (remainder <= 0) break;
      floored[key] = floored[key]! + unit;
      remainder -= unit;
    }
    setState(() {
      _weights = floored;
      _example = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final portfolio = _portfolio;
    final result =
        portfolio == null ? null : solvePlan(portfolio.applyTo(widget.base));

    return Scaffold(
      appBar: AppBar(title: const Text('포트폴리오 구성')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 단순 ↔ 포트폴리오 전환 (단순 선택 시 S4로 복귀)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('단순')),
                  ButtonSegment(value: true, label: Text('포트폴리오')),
                ],
                selected: const {true},
                showSelectedIcon: false,
                onSelectionChanged: (sel) {
                  if (sel.contains(false)) Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 12),
            // 예시 구성 칩 — "추천" 아님 (PRD S4-2)
            Wrap(
              spacing: 8,
              children: [
                for (final example in PortfolioExample.values)
                  ChoiceChip(
                    key: ValueKey('example-${example.name}'),
                    label: Text(example.label),
                    selected: _example == example,
                    onSelected: (_) => setState(() => _applyExample(example)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPremium
                  ? '예시 구성이에요 — 비중은 직접 바꿀 수 있어요'
                  : '예시 구성을 골라 결과를 체험해보세요',
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 8),
              _PremiumBanner(
                onTap: () => showPaywallSheet(context),
              ),
            ],
            const SizedBox(height: 12),
            _TotalGauge(weights: _weights, onNormalize: _normalize),
            const SizedBox(height: 4),
            for (final asset in PortfolioAsset.values)
              _AssetRow(
                asset: asset,
                weightBp: _weights[asset.key]!,
                stepBp: _sliderStepBp,
                enabled: isPremium,
                onChanged: (weightBp) => setState(() {
                  _weights[asset.key] = weightBp;
                  _example = null;
                }),
              ),
            const SizedBox(height: 12),
            _ResultCard(base: widget.base, portfolio: portfolio, result: result),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _showAssumptions(context),
                child: const Text('가정 보기'),
              ),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: portfolio == null
                  ? null
                  : () => Navigator.of(context).pop(PortfolioApplyResult(
                        returnBp: portfolio.portfolioReturnBp,
                        volatilityBp: portfolio.portfolioVolatilityBp,
                      )),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('이 구성으로 시뮬레이션'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '가정은 과거 장기 평균 기준(출처는 가정 보기) · '
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

  /// 자산별 가정·출처 공개 (PRD S4-2 수용 기준: "가정 보기"로 항상 공개)
  void _showAssumptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text('계산에 사용한 가정', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '실질(인플레 차감)·연 기하평균 기준. 해외자산은 USD 기준으로 '
              '원화 환변동이 반영되지 않았어요. 변동성은 자산 간 분산효과를 '
              '뺀 보수적 간이 추정이에요.',
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final asset in PortfolioAsset.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  asset.verified ? asset.label : '${asset.label} · 참고치',
                ),
                subtitle: Text(
                  '실질 ${(asset.realReturnBp / 100).toStringAsFixed(1)}% · '
                  '변동성 ${(asset.volatilityBp / 100).toStringAsFixed(0)}%\n'
                  '${asset.source}',
                ),
              ),
            const SizedBox(height: 8),
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
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 18, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '비중 편집은 프리미엄 — 예시 구성은 자유롭게 체험해보세요',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalGauge extends StatelessWidget {
  final Map<String, int> weights;
  final VoidCallback onNormalize;

  const _TotalGauge({required this.weights, required this.onNormalize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalBp = weights.values.fold(0, (s, w) => s + w);
    final isValid = totalBp == 10000;
    final color =
        isValid ? theme.colorScheme.primary : theme.colorScheme.error;
    final segments = [
      for (final asset in PortfolioAsset.values)
        if (weights[asset.key]! > 0)
          Expanded(
            flex: weights[asset.key]!,
            child: ColoredBox(color: assetColor(asset)),
          ),
    ];
    final leftover = 10000 - totalBp; // 미달 시 남는 칸(회색)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('자산군 비중', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '합계 ${(totalBp / 100).toStringAsFixed(1)}%',
              style: theme.textTheme.titleSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isValid)
              TextButton(
                onPressed: onNormalize,
                child: const Text('100%로 맞추기'),
              ),
          ],
        ),
        // 자산색 100% 스택 바 (Figma S4-2)
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                ...segments,
                if (leftover > 0)
                  Expanded(
                    flex: leftover,
                    child: ColoredBox(color: theme.colorScheme.outlineVariant),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  final PortfolioAsset asset;
  final int weightBp;
  final int stepBp;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _AssetRow({
    required this.asset,
    required this.weightBp,
    required this.stepBp,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = assetColor(asset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 자산색 점 (Figma S4-2)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: asset.label,
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text:
                          '  가정 ${(asset.realReturnBp / 100).toStringAsFixed(1)}%'
                          '${asset.verified ? '' : ' · 참고치'}',
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '${(weightBp / 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            // 슬라이더를 자산색으로 (Figma S4-2)
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              key: ValueKey('weight-${asset.key}'),
              value: weightBp.toDouble(),
              max: 10000,
              divisions: 10000 ~/ stepBp,
              onChanged:
                  enabled ? (value) => onChanged(value.round()) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PlanInput base;
  final PortfolioInput? portfolio;
  final FireResult? result;

  const _ResultCard({
    required this.base,
    required this.portfolio,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = portfolio;
    final r = result;

    final String headline;
    if (p == null) {
      headline = '합계를 100%로 맞추면 결과가 계산돼요';
    } else if (r == null || r.monthsToFire == null) {
      headline = '100년 안에 도달이 어려워요';
    } else if (r.monthsToFire == 0) {
      headline = '이미 FIRE 도달!';
    } else {
      headline = 'FIRE 나이 ${base.age0 + r.monthsToFire! ~/ 12}세';
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 구성이라면',
              style: theme.textTheme.labelMedium!.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              headline,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (p != null) ...[
              Text(
                '기대수익률(실질) ${(p.portfolioReturnBp / 100).toStringAsFixed(2)}% · '
                '변동성(간이) ${(p.portfolioVolatilityBp / 100).toStringAsFixed(2)}%',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              if (r != null && r.isReachable && r.monthsToFire! > 0)
                Text(
                  '${r.monthsToFire! ~/ 12}년 ${r.monthsToFire! % 12}개월 후 · '
                  '필요 자산 ${formatKoreanMoney(r.fireNumber)}원',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
