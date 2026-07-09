import 'package:flutter/material.dart';

/// S9. 페이월 (스텁)
///
/// TODO(payments): RevenueCat 연동 + 스토어 IAP. 구매/복원 버튼 활성화는
/// 결제 연동 시점에. 유저의 실제 숫자로 미리보기하는 원칙(PRD S9)에 따라
/// 성공 확률을 헤드라인에 노출한다.
Future<void> showPaywallSheet(BuildContext context, {double? successRate}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('파이어덤 프리미엄', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            successRate == null
                ? '내 계획의 리스크까지 확인해보세요'
                : '회원님 계획의 성공 확률 ${(successRate * 100).toStringAsFixed(0)}% — '
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
          const SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null, // 결제 연동 전까지 비활성
              child: Text('준비 중이에요 — 곧 만나요'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: null, // 결제 연동 전까지 비활성
              child: Text('구매 복원'),
            ),
          ),
        ],
      ),
    ),
  );
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
