import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'db/database.dart';
import 'notifications/reminder_scheduler.dart';
import 'repositories/settings_store.dart';
import 'repositories/snapshot_repository.dart';

/// 리마인더 설정 (settings 테이블). dayOfMonth 0 = 매월 말일 (PRD S10 기본값).
class ReminderSettings {
  final bool enabled;
  final int dayOfMonth;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    this.dayOfMonth = 0,
    this.hour = 20,
    this.minute = 0,
  });
}

/// 다가오는 리마인더 시각 계산 — 순수 함수.
/// 이미 기록된 달은 건너뛴다 (미기록 시에만 발송 — PRD S10 수용 기준).
List<DateTime> upcomingReminderTimes({
  required ReminderSettings settings,
  required DateTime now,
  required Set<int> recordedYms,
  int count = 3,
}) {
  final result = <DateTime>[];
  var year = now.year;
  var month = now.month;
  while (result.length < count) {
    final ym = year * 100 + month;
    if (!recordedYms.contains(ym)) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final day = settings.dayOfMonth == 0
          ? lastDay
          : math.min(settings.dayOfMonth, lastDay);
      final when = DateTime(year, month, day, settings.hour, settings.minute);
      if (when.isAfter(now)) result.add(when);
    }
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
  return result;
}

Future<ReminderSettings> loadReminderSettings(SettingsStore store) async {
  return ReminderSettings(
    enabled: await store.get<bool>(SettingKeys.reminderEnabled) ?? false,
    dayOfMonth: await store.get<int>(SettingKeys.reminderDay) ?? 0,
    hour: await store.get<int>(SettingKeys.reminderHour) ?? 20,
    minute: await store.get<int>(SettingKeys.reminderMinute) ?? 0,
  );
}

/// 리마인더 재예약. 설정 변경·스냅샷 저장·앱 기동 시 호출한다.
/// 알림은 부가 기능 — 실패해도 기록 흐름을 막지 않는다 (예: 테스트 환경).
Future<void> rescheduleReminders({
  required AppDatabase db,
  required ReminderScheduler scheduler,
  DateTime? now,
}) async {
  try {
    final settings = await loadReminderSettings(SettingsStore(db));
    if (!settings.enabled) {
      await scheduler.cancelAll();
      return;
    }
    final summaries = await SnapshotRepository(db).getSummaries();
    final times = upcomingReminderTimes(
      settings: settings,
      now: now ?? DateTime.now(),
      recordedYms: {for (final summary in summaries) summary.ym},
    );
    await scheduler.scheduleAll([
      for (final (index, time) in times.indexed)
        ReminderNotification(
          id: index + 1,
          when: time,
          title: '이번 달 자산 기록, 잊지 않으셨죠?',
          body: '3분이면 충분해요 — 계획 대비 어디쯤인지 확인해보세요',
        ),
    ]);
  } catch (error) {
    debugPrint('리마인더 예약 실패(무시): $error');
  }
}
