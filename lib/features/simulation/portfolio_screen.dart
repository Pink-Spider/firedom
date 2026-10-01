import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entitlements.dart';
import '../../engine/engine.dart';
import '../../l10n/l10n.dart';
import '../common/money.dart';
import '../common/portfolio_labels.dart';
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

/// 자산군별 표시 색 (Figma S4-2 팔레트) — 프리셋 자산용.
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

/// 직접 입력 자산군의 색 팔레트 (프리셋과 구분되는 톤)
const _customPalette = [
  Color(0xFF3E7C8C),
  Color(0xFF7A4E9E),
  Color(0xFF2E7D5B),
  Color(0xFF9E4E6B),
  Color(0xFF4E5A9E),
  Color(0xFF8C6A3E),
];

/// 직접 입력 자산군 메타 (사용자 지정 가정)
class _Custom {
  final String label;
  final int realReturnBp;
  final int volatilityBp;

  const _Custom(this.label, this.realReturnBp, this.volatilityBp);
}

/// 행/스택바 렌더링용 통합 스펙 (프리셋·커스텀 공통)
class _AssetSpec {
  final String key;
  final String label;
  final int realReturnBp;
  final int volatilityBp;
  final bool verified;
  final bool custom;
  final Color color;

  const _AssetSpec({
    required this.key,
    required this.label,
    required this.realReturnBp,
    required this.volatilityBp,
    required this.verified,
    required this.custom,
    required this.color,
  });
}

/// S4-2. 시뮬레이션 — 포트폴리오 구성 (PRD, 엔진명세 A11)
///
/// 단일 수익률 가정을 자산군별 비중으로 확장하는 What-if 심화.
/// 무료: 예시 구성 체험. 유료: 비중 편집·자산군 추가/삭제·직접 입력.
/// 비중 합계는 항상 100%로 강제(auto-lock) — 조절·삭제 시 나머지 재분배.
/// 여기서 만든 구성도 계획에는 반영되지 않는다 (S4 놀이터 원칙).
class PortfolioScreen extends ConsumerStatefulWidget {
  /// S4에서 조정 중이던 가정 (저축액·생활비 등은 그대로 쓴다)
  final PlanInput base;

  const PortfolioScreen({super.key, required this.base});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  /// assetKey(프리셋 또는 'custom:N') → weightBp
  late Map<String, int> _weights;

  /// 직접 입력 자산군 메타
  final Map<String, _Custom> _customs = {};
  int _customSeq = 0;
  PortfolioExample? _example;

  /// 비중 슬라이더 스텝 = 250bp(2.5%p). 재분배 단위 50bp와 배수 관계 유지.
  static const _sliderStepBp = 250;

  @override
  void initState() {
    super.initState();
    _applyExample(PortfolioExample.balanced);
  }

  void _applyExample(PortfolioExample example) {
    _customs.clear();
    _weights = {for (final h in example.build().holdings) h.assetKey: h.weightBp};
    _example = example;
  }

  _AssetSpec _specOf(String key) {
    final c = _customs[key];
    if (c != null) {
      final idx = _customs.keys.toList().indexOf(key);
      return _AssetSpec(
        key: key,
        label: c.label,
        realReturnBp: c.realReturnBp,
        volatilityBp: c.volatilityBp,
        verified: false,
        custom: true,
        color: _customPalette[idx % _customPalette.length],
      );
    }
    final a = PortfolioAsset.values.firstWhere((e) => e.key == key);
    return _AssetSpec(
      key: key,
      label: portfolioAssetLabel(context.l10n, a),
      realReturnBp: a.realReturnBp,
      volatilityBp: a.volatilityBp,
      verified: a.verified,
      custom: false,
      color: assetColor(a),
    );
  }

  /// 담긴 자산군 (프리셋은 enum 순서, 커스텀은 입력 순서)
  List<_AssetSpec> get _included => [
        for (final a in PortfolioAsset.values)
          if (_weights.containsKey(a.key)) _specOf(a.key),
        for (final k in _customs.keys)
          if (_weights.containsKey(k)) _specOf(k),
      ];

  /// 담기지 않은 프리셋 자산군 (추가 후보)
  List<PortfolioAsset> get _available =>
      [for (final a in PortfolioAsset.values) if (!_weights.containsKey(a.key)) a];

  int get _totalBp => _weights.values.fold(0, (sum, w) => sum + w);

  bool get _isValid => _totalBp == 10000;

  PortfolioInput? get _portfolio {
    if (!_isValid) return null;
    return PortfolioInput(holdings: [
      for (final spec in _included)
        if ((_weights[spec.key] ?? 0) > 0)
          PortfolioHolding(
            assetKey: spec.key,
            weightBp: _weights[spec.key]!,
            realReturnBp: spec.realReturnBp,
            volatilityBp: spec.volatilityBp,
          ),
    ]);
  }

  /// [others]에 [targetTotal]bp를 현재 비중 비례로 분배 (50bp 단위, 합 정확).
  Map<String, int> _distribute(List<String> others, int targetTotal) {
    final result = {for (final k in others) k: 0};
    if (others.isEmpty || targetTotal <= 0) return result;
    const unit = 50;
    final curTotal = others.fold(0, (s, k) => s + _weights[k]!);
    final raw = <String, double>{
      for (final k in others)
        k: curTotal == 0
            ? targetTotal / others.length
            : targetTotal * _weights[k]! / curTotal,
    };
    for (final k in others) {
      result[k] = (raw[k]! / unit).floor() * unit;
    }
    var rem = targetTotal - result.values.fold(0, (a, b) => a + b);
    final byFrac = others.toList()
      ..sort((a, b) => (raw[b]! - result[b]!).compareTo(raw[a]! - result[a]!));
    var i = 0;
    while (rem >= unit && byFrac.isNotEmpty) {
      result[byFrac[i % byFrac.length]] =
          result[byFrac[i % byFrac.length]]! + unit;
      rem -= unit;
      i++;
    }
    return result;
  }

  /// 한 자산의 비중을 바꾸고 나머지를 재분배해 총합 100% 유지 (auto-lock)
  void _setWeight(String key, int newBp) {
    newBp = newBp.clamp(0, 10000);
    final others = _weights.keys.where((k) => k != key).toList();
    setState(() {
      if (others.isEmpty) {
        _weights = {key: 10000};
      } else {
        _weights = {key: newBp, ..._distribute(others, 10000 - newBp)};
      }
      _example = null;
    });
  }

  void _removeAsset(String key) {
    setState(() {
      _weights.remove(key);
      _customs.remove(key);
      final others = _weights.keys.toList();
      if (others.isNotEmpty) _weights = _distribute(others, 10000);
      _example = null;
    });
  }

  /// 새 자산은 0%로 추가 (총합 100% 유지 — 슬라이더로 올리면 나머지가 줄어든다)
  void _addPreset(PortfolioAsset asset) => setState(() {
        _weights[asset.key] = 0;
        _example = null;
      });

  void _addCustom(String label, int realReturnBp, int volatilityBp) =>
      setState(() {
        final key = 'custom:${_customSeq++}';
        _customs[key] = _Custom(label, realReturnBp, volatilityBp);
        _weights[key] = 0;
        _example = null;
      });

  /// 자산군 추가 시트 — 직접 입력 + 담기지 않은 프리셋 (프리미엄)
  void _showAddAsset(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ListTile(
              key: const ValueKey('custom-add-tile'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.pfCustomInput),
              subtitle: Text(l10n.pfCustomInputSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCustomDialog(context);
              },
            ),
            if (_available.isNotEmpty) const Divider(),
            for (final asset in _available)
              ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: assetColor(asset),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  asset.verified
                      ? portfolioAssetLabel(l10n, asset)
                      : l10n.pfAssetReference(portfolioAssetLabel(l10n, asset)),
                ),
                subtitle: Text(
                  l10n.pfAssumedReturnVol(
                    (asset.realReturnBp / 100).toStringAsFixed(1),
                    (asset.volatilityBp / 100).toStringAsFixed(0),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addPreset(asset);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 직접 입력 다이얼로그 — 이름 + 가정 실질수익률(%) + 예상 변동성(%)
  void _showCustomDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final returnCtrl = TextEditingController();
    final volCtrl = TextEditingController(text: '15');
    final l10n = context.l10n;
    String? error;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          title: Text(l10n.pfCustomDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('custom-name'),
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.pfCustomNameLabel,
                  errorText: error,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('custom-return'),
                controller: returnCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.pfCustomReturnLabel,
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('custom-vol'),
                controller: volCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.pfCustomVolLabel,
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pfCustomNote,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final ret = double.tryParse(returnCtrl.text);
                if (name.isEmpty || ret == null) {
                  setDialog(() => error = l10n.pfCustomError);
                  return;
                }
                final vol = double.tryParse(volCtrl.text) ?? 15;
                Navigator.pop(dialogContext);
                _addCustom(name, (ret * 100).round(), (vol * 100).round());
              },
              child: Text(l10n.pfAdd),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final money = moneyFormatOf(context, ref);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    final portfolio = _portfolio;
    final result =
        portfolio == null ? null : solvePlan(portfolio.applyTo(widget.base));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pfTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 단순 ↔ 포트폴리오 전환 (단순 선택 시 S4로 복귀)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.pfModeSimple)),
                  ButtonSegment(
                      value: true, label: Text(l10n.pfModePortfolio)),
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
                    label: Text(portfolioExampleLabel(l10n, example)),
                    selected: _example == example,
                    onSelected: (_) => setState(() => _applyExample(example)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPremium ? l10n.pfHintPremium : l10n.pfHintFree,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 8),
              _PremiumBanner(onTap: () => showPaywallSheet(context)),
            ],
            const SizedBox(height: 12),
            // 기대수익률 — 자산군 비중 위에 크게 (조절 시 실시간 갱신)
            _ReturnHeadline(portfolio: portfolio),
            const SizedBox(height: 12),
            _TotalGauge(totalBp: _totalBp, specs: _included, weights: _weights),
            const SizedBox(height: 4),
            for (final spec in _included)
              _AssetRow(
                spec: spec,
                weightBp: _weights[spec.key]!,
                stepBp: _sliderStepBp,
                enabled: isPremium,
                onChanged: (weightBp) => _setWeight(spec.key, weightBp),
                onRemove: isPremium ? () => _removeAsset(spec.key) : null,
              ),
            if (isPremium)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('add-asset'),
                  onPressed: () => _showAddAsset(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.pfAddAsset),
                ),
              ),
            const SizedBox(height: 12),
            _ResultCard(
              base: widget.base,
              portfolio: portfolio,
              result: result,
              money: money,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _showAssumptions(context),
                child: Text(l10n.pfShowAssumptions),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.pfApplyCta),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.pfFooterNote(l10n.disclaimerSimulation),
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
    final l10n = context.l10n;
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
            Text(l10n.pfAssumptionsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.pfAssumptionsCaveat,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final asset in PortfolioAsset.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  asset.verified
                      ? portfolioAssetLabel(l10n, asset)
                      : l10n.pfAssetReference(portfolioAssetLabel(l10n, asset)),
                ),
                subtitle: Text(
                  '${l10n.pfRealReturnVol(
                    (asset.realReturnBp / 100).toStringAsFixed(1),
                    (asset.volatilityBp / 100).toStringAsFixed(0),
                  )}\n'
                  '${portfolioAssetSource(l10n, asset)}',
                ),
              ),
            // 직접 입력 자산군 (담긴 것만)
            for (final key in _customs.keys)
              if (_weights.containsKey(key))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pfAssetCustom(_customs[key]!.label)),
                  subtitle: Text(
                    '${l10n.pfRealReturnVol(
                      (_customs[key]!.realReturnBp / 100).toStringAsFixed(1),
                      (_customs[key]!.volatilityBp / 100).toStringAsFixed(0),
                    )}\n'
                    '${l10n.pfCustomSource}',
                  ),
                ),
            const SizedBox(height: 8),
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
                  context.l10n.pfPremiumBanner,
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
  final int totalBp;
  final List<_AssetSpec> specs;
  final Map<String, int> weights;

  const _TotalGauge({
    required this.totalBp,
    required this.specs,
    required this.weights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = totalBp == 10000;
    final color =
        isValid ? theme.colorScheme.primary : theme.colorScheme.error;
    final segments = [
      for (final spec in specs)
        if ((weights[spec.key] ?? 0) > 0)
          Expanded(
            flex: weights[spec.key]!,
            child: ColoredBox(color: spec.color),
          ),
    ];
    final leftover = 10000 - totalBp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(context.l10n.pfWeightsTitle, style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              context.l10n.pfTotalPercent((totalBp / 100).toStringAsFixed(1)),
              style: theme.textTheme.titleSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
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
  final _AssetSpec spec;
  final int weightBp;
  final int stepBp;
  final bool enabled;
  final ValueChanged<int> onChanged;

  /// 이 자산군을 포트폴리오에서 뺀다 (프리미엄만 — null이면 삭제 버튼 숨김)
  final VoidCallback? onRemove;

  const _AssetRow({
    required this.spec,
    required this.weightBp,
    required this.stepBp,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final color = spec.color;
    final tag = spec.custom
        ? l10n.pfTagCustom
        : spec.verified
            ? ''
            : l10n.pfTagReference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: spec.label,
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text:
                          '  ${l10n.pfAssumedReturn((spec.realReturnBp / 100).toStringAsFixed(1))}$tag',
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
            if (onRemove != null)
              IconButton(
                key: ValueKey('remove-${spec.key}'),
                visualDensity: VisualDensity.compact,
                tooltip: l10n.pfRemoveAssetTooltip,
                icon: Icon(Icons.close,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                onPressed: onRemove,
              ),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              key: ValueKey('weight-${spec.key}'),
              value: weightBp.toDouble().clamp(0, 10000),
              max: 10000,
              divisions: 10000 ~/ stepBp,
              onChanged: enabled ? (value) => onChanged(value.round()) : null,
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
  final MoneyFormat money;

  const _ResultCard({
    required this.base,
    required this.portfolio,
    required this.result,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final p = portfolio;
    final r = result;

    final String headline;
    if (p == null) {
      headline = l10n.pfResultNeedTotal;
    } else if (r == null || r.monthsToFire == null) {
      headline = l10n.pfResultUnreachable;
    } else if (r.monthsToFire == 0) {
      headline = l10n.pfResultAlreadyFire;
    } else {
      headline = l10n.pfResultFireAge(base.age0 + r.monthsToFire! ~/ 12);
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.pfResultLead,
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
            if (p != null && r != null && r.isReachable && r.monthsToFire! > 0)
              Text(
                l10n.pfResultDetail(
                  l10n.yearsMonthsLabel(
                      r.monthsToFire! ~/ 12, r.monthsToFire! % 12),
                  money.compact(r.fireNumber),
                ),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 기대수익률(실질)·변동성을 자산군 비중 위에 크게 표시 (S4-2, 조절 시 실시간)
class _ReturnHeadline extends StatelessWidget {
  final PortfolioInput? portfolio;

  const _ReturnHeadline({required this.portfolio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final p = portfolio;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: p == null
          ? Text(
              l10n.pfHeadlineNeedTotal,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.pfExpectedReturn,
                        style: theme.textTheme.labelMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    Text(
                      '${(p.portfolioReturnBp / 100).toStringAsFixed(2)}%',
                      style: theme.textTheme.headlineMedium!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.pfVolatilitySimple,
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    Text(
                      '${(p.portfolioVolatilityBp / 100).toStringAsFixed(2)}%',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
