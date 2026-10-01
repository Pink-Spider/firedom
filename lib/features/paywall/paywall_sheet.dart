import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/entitlements.dart';
import '../../l10n/l10n.dart';

/// 구독 화면에 반드시 노출해야 하는 법적 링크 (App Store 심사 지침 3.1.2(c)).
///
/// 자체 이용약관을 두지 않고 Apple 표준 EULA를 그대로 쓴다 — 그럴 때는
/// 앱 안과 스토어 설명 양쪽에 이 링크가 있어야 한다.
const paywallTermsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const paywallPrivacyUrl = 'https://pink-spider.github.io/firedom-privacy/';

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

  String _planLabel(AppLocalizations l10n, Package p) => switch (p.packageType) {
        PackageType.annual => l10n.paywallPlanAnnual,
        PackageType.monthly => l10n.paywallPlanMonthly,
        PackageType.weekly => l10n.paywallPlanWeekly,
        PackageType.lifetime => l10n.paywallPlanLifetime,
        _ => p.storeProduct.title,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paywallTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (isPremium) ...[
            Text(l10n.paywallAlreadyPremium,
                style: theme.textTheme.bodyMedium),
          ] else ...[
            Text(
              widget.successRate == null
                  ? l10n.paywallTeaserGeneric
                  : l10n.paywallTeaserWithRate(
                      (widget.successRate! * 100).toStringAsFixed(0)),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // 지금 제공되는 기능만 표시한다. 미출시 기능은 페이월에 올리지 않는다
            // — '결제했는데 안 열린다'는 오인 구매·환불·심사 리스크를 만든다.
            _FeatureRow(l10n.paywallFeatureMonteCarlo),
            _FeatureRow(l10n.paywallFeaturePortfolio),
            _FeatureRow(l10n.paywallFeatureScenarios),
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
                        // 가격은 스토어(RevenueCat) localized price 문자열 그대로
                        title: Text(l10n.paywallPlanPrice(
                            _planLabel(l10n, p), p.storeProduct.priceString)),
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
                      : Text(l10n.paywallSubscribe),
                ),
              ),
            ] else ...[
              // 미구성(연동/상품 준비 전) — 안내 가격 + 준비 중 버튼
              Center(
                child: Text(
                  l10n.paywallFallbackPricing,
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
                  child: Text(l10n.paywallSubscribe),
                ),
              ),
            ],
            Center(
              child: TextButton(
                onPressed: _restore,
                child: Text(l10n.paywallRestore),
              ),
            ),
            Center(
              child: Text(
                l10n.paywallAutoRenewNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Center(child: _LegalLinks()),
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
        SnackBar(content: Text(context.l10n.paywallPurchaseFailed)),
      );
    }
  }

  Future<void> _purchaseStub() async {
    final ok = await ref.read(entitlementServiceProvider).purchase();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.paywallStoreNotReady)),
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
        content: Text(ok
            ? context.l10n.paywallRestored
            : context.l10n.paywallNothingToRestore),
      ),
    );
  }
}

/// 이용약관(EULA)·개인정보 처리방침 링크.
///
/// 구독을 파는 화면에는 이 두 링크가 **실제로 열려야** 한다 — 텍스트만 두면
/// 심사에서 3.1.2(c)로 리젝된다.
class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.paywallBrowserFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final style = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        InkWell(
          key: const ValueKey('paywall-terms-link'),
          onTap: () => _open(context, paywallTermsUrl),
          child: Text(l10n.paywallTerms, style: style),
        ),
        Text('·',
            style: theme.textTheme.bodySmall!
                .copyWith(color: theme.colorScheme.onSurfaceVariant)),
        InkWell(
          key: const ValueKey('paywall-privacy-link'),
          onTap: () => _open(context, paywallPrivacyUrl),
          child: Text(l10n.paywallPrivacy, style: style),
        ),
      ],
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
