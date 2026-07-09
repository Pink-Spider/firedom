import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import '../../data/db/providers.dart';
import '../../data/repositories/plan_repository.dart';
import '../../engine/engine.dart';
import '../common/deviation_badge.dart';
import '../common/milestone_labels.dart';
import '../home/home_screen.dart';

/// S8-③. 결과 리빌 (PRD): 순자산 증감 → 저축률 → 궤도 편차 갱신.
/// 숫자 카운트업 연출.
class SnapshotResultScreen extends ConsumerWidget {
  static const path = '/snapshot/result';

  final int ym;

  const SnapshotResultScreen({super.key, required this.ym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaries = ref.watch(snapshotSummariesProvider).value;
    final plan = ref.watch(activePlanRowProvider).value;

    final index = summaries?.indexWhere((s) => s.ym == ym) ?? -1;
    if (summaries == null || index < 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final current = summaries[index];
    final previous = index > 0 ? summaries[index - 1] : null;
    final delta = previous == null ? null : current.netWorth - previous.netWorth;
    final rate = (current.snapshot.income != null &&
            current.snapshot.expense != null)
        ? savingRate(
            income: current.snapshot.income!,
            expense: current.snapshot.expense!,
          )
        : null;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('${ym % 100}월 기록 완료!',
                style: theme.textTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('순자산', style: theme.textTheme.labelLarge),
            _CountUpMoney(
              value: current.netWorth,
              style: theme.textTheme.displaySmall!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (delta != null) ...[
              const SizedBox(height: 4),
              Text(
                delta >= 0
                    ? '전월 대비 +${formatKoreanMoney(delta)}원'
                    : '전월 대비 −${formatKoreanMoney(-delta)}원',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: delta >= 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (rate != null)
              Card(
                child: ListTile(
                  title: const Text('이번 달 저축률'),
                  trailing: Text(
                    '${(rate.clamp(-1.0, 1.0) * 100).round()}%',
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (plan != null && summaries.length >= 2)
              Card(
                child: ListTile(
                  title: const Text('궤도'),
                  trailing: DeviationBadge(
                    plan: plan,
                    result: solvePlan(planInputOf(plan)),
                    actualAssets: current.netWorth,
                    atYm: current.ym,
                  ),
                ),
              )
            else
              Text(
                '다음 기록부터 궤도 비교가 시작돼요',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Builder(builder: (context) {
              // 이번 달 달성 마일스톤 축하 (PRD S8 결과 리빌)
              final milestones =
                  ref.watch(milestonesProvider).value ?? const [];
              final achievedNow = [
                for (final milestone in milestones)
                  if (milestone.achievedYm == ym) milestone,
              ];
              if (achievedNow.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('마일스톤 달성',
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        for (final milestone in achievedNow)
                          Text(
                            milestoneLabel(milestone.milestoneKey),
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go(HomeScreen.path),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('홈으로'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 숫자 카운트업 연출 (PRD S8 결과 리빌)
class _CountUpMoney extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const _CountUpMoney({required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) =>
          Text('${formatKoreanMoney(animated.round())}원', style: style),
    );
  }
}
