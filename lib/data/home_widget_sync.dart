import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/ym.dart';
import '../engine/engine.dart';
import '../l10n/l10n.dart';
import 'db/database.dart';
import 'repositories/plan_repository.dart';
import 'repositories/settings_store.dart';
import 'repositories/snapshot_repository.dart';

/// iOS 위젯과 데이터를 공유하는 App Group ID (Xcode 타겟 설정과 일치해야 함)
const appGroupId = 'group.app.firedom.firedom';

/// W1 위젯 페이로드 (PRD): D-day + 진행률 + 편차 배지.
/// 금액은 위젯에 절대 노출하지 않는다 (프라이버시).
class WidgetPayload {
  final String ddayText;
  final int progressPercent;
  final String deviationText;

  const WidgetPayload({
    required this.ddayText,
    required this.progressPercent,
    required this.deviationText,
  });
}

/// [l10n]은 BuildContext 없이 얻는다 — `l10nFromSettings` 또는
/// `lookupAppLocalizations(resolveLocale(code))`.
WidgetPayload buildWidgetPayload({
  required Plan? plan,
  required List<SnapshotSummary> summaries,
  required int currentYm,
  required AppLocalizations l10n,
}) {
  if (plan == null) {
    return WidgetPayload(
      ddayText: l10n.widgetNoPlan,
      progressPercent: 0,
      deviationText: '',
    );
  }

  final input = planInputOf(plan);
  final result = solvePlan(input);
  final latest = summaries.isEmpty ? null : summaries.last;
  final currentAssets = latest?.netWorth ?? plan.currentAssets;
  final progress = result.fireNumber <= 0
      ? 0
      : (currentAssets * 100 / result.fireNumber).clamp(0, 100).round();

  final String ddayText;
  final months = result.monthsToFire;
  if (months == null) {
    ddayText = l10n.widgetCheckAssumptions;
  } else {
    final elapsed = math.max(0, ymDiffMonths(plan.startedYm, currentYm));
    final remaining = math.max(0, months - elapsed);
    if (remaining == 0 || currentAssets >= result.fireNumber) {
      ddayText = l10n.widgetGoalReached;
    } else {
      final years = remaining ~/ 12;
      final remainMonths = remaining % 12;
      ddayText = l10n.widgetUntilFree(years == 0
          ? l10n.monthsLabel(remainMonths)
          : l10n.yearsMonthsLabel(years, remainMonths));
    }
  }

  var deviationText = '';
  if (latest != null && summaries.length >= 2 && result.isReachable) {
    final deviation = trajectoryDeviationMonths(
      planAssetsByMonth: result.assetsByMonth,
      fireNumber: result.fireNumber,
      actualAssets: latest.netWorth,
      monthsElapsed: math.max(0, ymDiffMonths(plan.startedYm, latest.ym)),
    );
    if (deviation == null) {
      deviationText = l10n.widgetGoalReached;
    } else {
      final rounded = deviation.round();
      deviationText = rounded >= 1
          ? l10n.widgetAheadOfPlan(rounded)
          : rounded <= -1
              ? l10n.widgetBehindPlan(-rounded)
              : l10n.widgetOnTrack;
    }
  }

  return WidgetPayload(
    ddayText: ddayText,
    progressPercent: progress,
    deviationText: deviationText,
  );
}

typedef HomeWidgetSync = Future<void> Function(AppDatabase db);

/// 위젯 동기화 추상화 — 테스트에서는 no-op으로 override.
/// (mock되지 않은 플랫폼 채널은 테스트에서 Future가 완료되지 않아 흐름이 멈춘다)
final homeWidgetSyncProvider = Provider<HomeWidgetSync>(
  (ref) => syncHomeWidget,
);

/// 위젯 데이터 갱신 — 스냅샷 저장·계획 변경·앱 기동 시 호출.
/// 위젯은 부가 기능: 실패해도 본 흐름을 막지 않는다.
Future<void> syncHomeWidget(AppDatabase db) async {
  try {
    final plan = await PlanRepository(db).getActivePlan();
    final summaries = await SnapshotRepository(db).getSummaries();
    final l10n = await l10nFromSettings(SettingsStore(db));
    final payload = buildWidgetPayload(
      plan: plan,
      summaries: summaries,
      currentYm: nowYm(),
      l10n: l10n,
    );

    if (!kIsWeb && Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
    await HomeWidget.saveWidgetData<String>('dday_text', payload.ddayText);
    await HomeWidget.saveWidgetData<int>('progress', payload.progressPercent);
    await HomeWidget.saveWidgetData<String>(
        'deviation_text', payload.deviationText);
    await HomeWidget.updateWidget(
      androidName: 'FiredomWidgetProvider',
      iOSName: 'FiredomWidget',
    );
  } catch (error) {
    debugPrint('위젯 갱신 실패(무시): $error');
  }
}
