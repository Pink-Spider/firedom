import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ym.dart';
import '../../data/db/database.dart';
import '../../engine/engine.dart';

/// 궤도 편차 배지 (A7). 사실 표시만 — 행동 지시 금지 (제품 원칙).
class DeviationBadge extends StatelessWidget {
  final Plan plan;
  final FireResult result;
  final int actualAssets;

  /// 실제 자산이 기록된 연월 (yyyymm)
  final int atYm;

  const DeviationBadge({
    super.key,
    required this.plan,
    required this.result,
    required this.actualAssets,
    required this.atYm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var background = theme.colorScheme.secondaryContainer;
    var foreground = theme.colorScheme.onSecondaryContainer;
    final String label;

    if (!result.isReachable) {
      label = '가정 점검 필요';
    } else {
      final deviation = trajectoryDeviationMonths(
        planAssetsByMonth: result.assetsByMonth,
        fireNumber: result.fireNumber,
        actualAssets: actualAssets,
        monthsElapsed: math.max(0, ymDiffMonths(plan.startedYm, atYm)),
      );
      if (deviation == null) {
        label = '이미 목표 도달!';
        background = theme.colorScheme.primary;
        foreground = theme.colorScheme.onPrimary;
      } else {
        final rounded = deviation.round();
        if (rounded >= 1) {
          label = '계획보다 $rounded개월 앞서는 중';
          background = theme.colorScheme.primaryContainer;
          foreground = theme.colorScheme.onPrimaryContainer;
        } else if (rounded <= -1) {
          // 비난 톤 금지 (제품 원칙)
          label = '계획보다 ${-rounded}개월 뒤 — 따라잡을 수 있어요';
        } else {
          label = '계획대로 진행 중';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium!
            .copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
