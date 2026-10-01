import 'package:drift/native.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/notifications/reminder_scheduler.dart';
import 'package:firedom/data/reminders.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeScheduler implements ReminderScheduler {
  final List<List<ReminderNotification>> batches = [];
  int cancelCount = 0;

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> scheduleAll(List<ReminderNotification> notifications) async {
    batches.add(notifications);
  }

  @override
  Future<void> cancelAll() async => cancelCount++;
}

void main() {
  const defaults = ReminderSettings(enabled: true); // 말일 20:00

  group('upcomingReminderTimes (S10)', () {
    test('기본값: 매월 말일 20:00, 3개월치', () {
      final times = upcomingReminderTimes(
        settings: defaults,
        now: DateTime(2026, 2, 10),
        recordedYms: {},
      );
      expect(times, [
        DateTime(2026, 2, 28, 20, 0), // 2026년 2월은 28일까지
        DateTime(2026, 3, 31, 20, 0),
        DateTime(2026, 4, 30, 20, 0),
      ]);
    });

    test('이번 달 알림 시각이 지났으면 다음 달부터', () {
      final times = upcomingReminderTimes(
        settings: defaults,
        now: DateTime(2026, 7, 31, 21, 0),
        recordedYms: {},
      );
      expect(times.first, DateTime(2026, 8, 31, 20, 0));
    });

    test('기록된 달은 건너뛴다 (미기록 시에만 발송 — 수용 기준)', () {
      final times = upcomingReminderTimes(
        settings: defaults,
        now: DateTime(2026, 7, 1),
        recordedYms: {202607},
      );
      expect(times.first, DateTime(2026, 8, 31, 20, 0));
      expect(times.length, 3);
    });

    test('날짜 지정: 매월 15일 9시 30분, 연도 경계 처리', () {
      final times = upcomingReminderTimes(
        settings: const ReminderSettings(
            enabled: true, dayOfMonth: 15, hour: 9, minute: 30),
        now: DateTime(2026, 11, 20),
        recordedYms: {},
      );
      expect(times, [
        DateTime(2026, 12, 15, 9, 30),
        DateTime(2027, 1, 15, 9, 30),
        DateTime(2027, 2, 15, 9, 30),
      ]);
    });
  });

  group('rescheduleReminders — 알림 문구는 설정 언어를 따른다', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> enable(String locale) async {
      final store = SettingsStore(db);
      await store.set(SettingKeys.reminderEnabled, true);
      await store.set(SettingKeys.locale, locale);
    }

    test('ko: 제목·본문·Android 채널 문구', () async {
      await enable('ko');
      final scheduler = _FakeScheduler();
      await rescheduleReminders(
        db: db,
        scheduler: scheduler,
        now: DateTime(2026, 2, 10),
      );
      expect(scheduler.batches, hasLength(1));
      final first = scheduler.batches.single.first;
      expect(first.title, '이번 달 자산 기록, 잊지 않으셨죠?');
      expect(first.body, '3분이면 충분해요 — 계획 대비 어디쯤인지 확인해보세요');
      expect(first.channelName, '월간 기록 리마인더');
      expect(first.channelDescription, '월 1회 자산 기록 알림 (미기록 월에만)');
      expect(first.when, DateTime(2026, 2, 28, 20, 0));
    });

    test('en: 영어 문구로 예약', () async {
      await enable('en');
      final scheduler = _FakeScheduler();
      await rescheduleReminders(
        db: db,
        scheduler: scheduler,
        now: DateTime(2026, 2, 10),
      );
      final first = scheduler.batches.single.first;
      expect(first.title, 'Your monthly asset record is waiting');
      expect(first.channelName, 'Monthly record reminder');
    });

    test('꺼져 있으면 전부 취소하고 예약하지 않는다', () async {
      final scheduler = _FakeScheduler();
      await rescheduleReminders(db: db, scheduler: scheduler);
      expect(scheduler.cancelCount, 1);
      expect(scheduler.batches, isEmpty);
    });
  });
}
