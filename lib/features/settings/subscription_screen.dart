import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/entitlements.dart';
import '../../l10n/l10n.dart';

/// S10-2. 구독 관리 (PRD) — 구독자 전용.
///
/// 구독은 스토어 계정으로 관리되므로 앱은 상태 표시·딥링크·복원만 담당한다.
/// TODO(payments): RevenueCat 연동 후 CustomerInfo의 플랜(월/연)·다음 갱신일을
/// 표시한다 — 연동 전에는 스토어 확인 안내로 대체.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Uri get _storeSubscriptionUri =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? Uri.parse('https://apps.apple.com/account/subscriptions')
          : Uri.parse('https://play.google.com/store/account/subscriptions');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? l10n.subActiveTitle : l10n.subInactiveTitle,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium ? l10n.subActiveBody : l10n.subInactiveBody,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.subPlanRenewal),
              subtitle: Text(l10n.subPlanRenewalSubtitle),
            ),
            Text(
              l10n.subManagedByStore,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const ValueKey('store-subscription-button'),
              onPressed: () => _openStore(context),
              child: Text(l10n.subManageInStore),
            ),
            TextButton(
              onPressed: () => _restore(context, ref),
              child: Text(l10n.subRestore),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    try {
      final ok = await launchUrl(
        _storeSubscriptionUri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('launch failed');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.subStoreOpenFailed)),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(entitlementServiceProvider).restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            ok ? context.l10n.subRestored : context.l10n.subRestoreNotFound),
      ),
    );
  }
}
