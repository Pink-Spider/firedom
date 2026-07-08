import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import '../../data/active_plan_store.dart';
import '../../engine/engine.dart';
import '../onboarding/onboarding_screen.dart';

/// S3. 홈 — 궤도 대시보드 (임시: 저장된 계획 요약만 표시)
class HomeScreen extends ConsumerWidget {
  static const path = '/';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(activePlanProvider);

    if (plan == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('아직 계획이 없어요'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(OnboardingScreen.path),
                child: const Text('60초 만에 계획 만들기'),
              ),
            ],
          ),
        ),
      );
    }

    final result = solvePlan(plan);
    final months = result.monthsToFire;

    return Scaffold(
      appBar: AppBar(title: const Text('파이어덤')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('나의 FIRE 계획', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Text(
                      months == null
                          ? '도달 시점 재계산 필요'
                          : months == 0
                              ? '이미 FIRE에 도달했어요'
                              : 'FIRE 나이 ${plan.age0 + months ~/ 12}세 · '
                                  '${months ~/ 12}년 ${months % 12}개월 남음',
                      style: theme.textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '목표 자산 ${formatKoreanMoney(result.fireNumber)}원 · '
                      '월 저축 ${formatKoreanMoney(plan.monthlySaving)}원',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '궤도 대시보드(계획 vs 실제)는 월 스냅샷 기록과 함께 준비 중이에요.',
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
