import 'package:firedom/data/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
