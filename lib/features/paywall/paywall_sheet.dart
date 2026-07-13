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
            // 지금 제공되는 프리미엄 기능만 체크로 명시 (오인 구매 방지)
            const _FeatureRow('몬테카를로 상세 분포 · 자산 고갈 나이 분포'),
            const _FeatureRow('포트폴리오 비중 자유 편집'),
            // 아직 미출시 — '출시 예정' 배지로 구분 (스토어 심사·오인 방지)
            const _FeatureRow('시나리오 무제한 저장 · 나란히 비교', comingSoon: true),
            const _FeatureRow('은퇴 직후 폭락(시퀀스 리스크) 스트레스 테스트',
                comingSoon: true),
            const _FeatureRow('연금 · 세제 뷰', comingSoon: true),
            const SizedBox(height: 16),
            // 연간 우선 노출 (월 1회 앱 특성상 연간이 리텐션에 유리 — PRD S9)
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

  /// 미출시 기능 — 흐린 아이콘 + '출시 예정' 배지 (오인 구매 방지)
  final bool comingSoon;

  const _FeatureRow(this.label, {this.comingSoon = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = comingSoon
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(comingSoon ? Icons.schedule : Icons.check_circle,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: comingSoon
                  ? theme.textTheme.bodyMedium!
                      .copyWith(color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
          if (comingSoon)
            Text('출시 예정',
                style: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
        ],
      ),
    );
  }
}
