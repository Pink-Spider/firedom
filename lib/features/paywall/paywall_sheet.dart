import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../data/entitlements.dart';

/// S9. 페이월 (PRD)
///
/// 유저의 실제 숫자(성공 확률)로 미리보기. RevenueCat 구성 시 스토어 가격으로
/// 플랜(연/월)을 선택해 실제 결제하고, 미구성(연동 전) 시 안내만 표시한다.
Future<void> showPaywallSheet(BuildContext context, {double? successRate}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => PaywallSheet(successRate: successRate),
  );
}

class PaywallSheet extends ConsumerStatefulWidget {
  final double? successRate;

  const PaywallSheet({super.key, this.successRate});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  List<Package> _packages = const [];
  Package? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final svc = ref.read(entitlementServiceProvider);
    if (svc.isConfigured) _loadPackages(svc);
  }

  Future<void> _loadPackages(EntitlementService svc) async {
    final pkgs = await svc.availablePackages();
    if (!mounted) return;
    setState(() {
      _packages = pkgs;
      _selected = _preferAnnual(pkgs);
    });
  }

  /// 연간을 기본 선택 (없으면 첫 패키지) — PRD S9 연간 우선
  Package? _preferAnnual(List<Package> pkgs) {
    for (final p in pkgs) {
      if (p.packageType == PackageType.annual) return p;
    }
    return pkgs.isEmpty ? null : pkgs.first;
  }

  String _planLabel(Package p) => switch (p.packageType) {
        PackageType.annual => '연간',
        PackageType.monthly => '월간',
        PackageType.weekly => '주간',
        PackageType.lifetime => '평생',
        _ => p.storeProduct.title,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('파이어덤 프리미엄', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (isPremium) ...[
            Text('이미 프리미엄을 이용 중이에요 🎉',
                style: theme.textTheme.bodyMedium),
          ] else ...[
            Text(
              widget.successRate == null
                  ? '내 계획의 리스크까지 확인해보세요'
                  : '회원님 계획의 성공 확률 ${(widget.successRate! * 100).toStringAsFixed(0)}% — '
                      '상세 분포와 자산 고갈 리스크를 확인해보세요',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // 지금 제공되는 기능만 표시한다. 미출시 기능은 페이월에 올리지 않는다
            // — '결제했는데 안 열린다'는 오인 구매·환불·심사 리스크를 만든다.
            const _FeatureRow('몬테카를로 상세 분포 · 자산 고갈 나이 분포'),
            const _FeatureRow('포트폴리오 비중 자유 편집'),
            const _FeatureRow('시나리오 무제한 저장 · 나란히 비교'),
            const SizedBox(height: 16),
            if (_packages.isNotEmpty) ...[
              // 스토어 실제 가격으로 플랜 선택 (연간 기본)
              RadioGroup<Package>(
                groupValue: _selected,
                onChanged: (v) {
                  if (_busy) return;
                  setState(() => _selected = v);
                },
                child: Column(
                  children: [
                    for (final p in _packages)
                      RadioListTile<Package>(
                        key: ValueKey('plan-${p.packageType.name}'),
                        contentPadding: EdgeInsets.zero,
                        value: p,
                        title: Text(
                            '${_planLabel(p)} · ${p.storeProduct.priceString}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _busy || _selected == null ? null : _purchaseSelected,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('구독 시작하기'),
                ),
              ),
            ] else ...[
              // 미구성(연동/상품 준비 전) — 안내 가격 + 준비 중 버튼
              Center(
                child: Text(
                  '연 39,000원 — 월 3,250원꼴 · 34% 할인\n월 4,900원 · 7일 무료 체험',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _purchaseStub,
                  child: const Text('구독 시작하기'),
                ),
              ),
            ],
            Center(
              child: TextButton(
                onPressed: _restore,
                child: const Text('구매 복원'),
              ),
            ),
            Center(
              child: Text(
                '무료 체험 종료 후 선택한 플랜으로 자동 갱신되며, 언제든 '
                '스토어 계정에서 해지할 수 있어요.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _purchaseSelected() async {
    final pkg = _selected;
    if (pkg == null) return;
    setState(() => _busy = true);
    final ok = await ref.read(entitlementServiceProvider).purchasePackage(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제가 완료되지 않았어요')),
      );
    }
  }

  Future<void> _purchaseStub() async {
    final ok = await ref.read(entitlementServiceProvider).purchase();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스토어 결제 연동 준비 중이에요 — 곧 열려요')),
      );
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _restore() async {
    final ok = await ref.read(entitlementServiceProvider).restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '구매를 복원했어요' : '복원할 구매 내역이 없어요 (연동 준비 중)'),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;

  /// 페이월에는 **지금 제공되는 기능만** 올린다. 미출시 기능을 '출시 예정'으로
  /// 올려두면 결제 후 열리지 않아 오인 구매·환불·심사 리스크가 된다.
  /// (자산 화면의 연금·세제 잠금도 같은 이유로 v1.0에서 제거했다)
  const _FeatureRow(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
