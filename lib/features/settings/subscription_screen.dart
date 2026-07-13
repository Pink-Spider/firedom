import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/entitlements.dart';

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
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('구독 관리')),
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
                      isPremium ? '파이어덤 프리미엄 이용 중 🎉' : '구독이 확인되지 않아요',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? '몬테카를로 상세 · 시나리오 비교 · 연금 뷰 · 포트폴리오 편집'
                          : '스토어에서 결제한 이력이 있다면 아래에서 복원해보세요',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('플랜 · 다음 갱신일'),
              subtitle: Text('스토어 구독 화면에서 확인할 수 있어요'),
            ),
            Text(
              '구독은 스토어 계정으로 관리돼요 — 플랜 변경과 해지는 스토어에서 할 수 있고, '
              '해지해도 남은 기간까지는 프리미엄이 유지돼요.',
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const ValueKey('store-subscription-button'),
              onPressed: () => _openStore(context),
              child: const Text('스토어에서 구독 관리'),
            ),
            TextButton(
              onPressed: () => _restore(context, ref),
              child: const Text('구매 복원'),
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
        const SnackBar(content: Text('스토어를 열 수 없어요 — 스토어 앱에서 구독을 확인해주세요')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(entitlementServiceProvider).restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '구매를 복원했어요'
            : '복원할 구매를 찾지 못했어요 (결제 연동 준비 중)'),
      ),
    );
  }
}
