import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entitlements.dart';

/// S9. 페이월 (PRD)
///
/// 유저의 실제 숫자(성공 확률)로 미리보기. 구매/복원은 EntitlementService를
/// 통해 동작하며, RevenueCat 연동 전에는 안내만 표시한다.
Future<void> showPaywallSheet(BuildContext context, {double? successRate}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => PaywallSheet(successRate: successRate),
  );
}

class PaywallSheet extends ConsumerWidget {
  final double? successRate;

  const PaywallSheet({super.key, this.successRate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              successRate == null
                  ? '내 계획의 리스크까지 확인해보세요'
                  : '회원님 계획의 성공 확률 ${(successRate! * 100).toStringAsFixed(0)}% — '
                      '상세 분포와 자산 고갈 리스크를 확인해보세요',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const _FeatureRow('몬테카를로 상세 분포 · 자산 고갈 나이 분포'),
            const _FeatureRow('시나리오 무제한 저장 · 나란히 비교'),
            const _FeatureRow('은퇴 직후 폭락(시퀀스 리스크) 스트레스 테스트'),
            const _FeatureRow('연금 · 세제 뷰'),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '월 4,900원 · 연 39,000원 (7일 무료 체험)',
                style: theme.textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _purchase(context, ref),
                child: const Text('구독 시작하기'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => _restore(context, ref),
                child: const Text('구매 복원'),
              ),
            ),
            Center(
              child: Text(
                '구독은 스토어 계정으로 관리되며 언제든 해지할 수 있어요',
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

  Future<void> _purchase(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(entitlementServiceProvider).purchase();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스토어 결제 연동 준비 중이에요 — 곧 열려요')),
      );
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(entitlementServiceProvider).restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '구매를 복원했어요' : '복원할 구매 내역이 없어요 (연동 준비 중)'),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;

  const _FeatureRow(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
