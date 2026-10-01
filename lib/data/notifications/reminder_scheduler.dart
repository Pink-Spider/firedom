import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotification {
  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// Android 알림 채널 이름·설명 (설정 언어의 l10n 문자열).
  /// 채널 ID는 고정([monthlyReminderChannelId])이고 표시 문구만 언어를 따른다.
  final String channelName;
  final String channelDescription;

  const ReminderNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });
}

/// Android 알림 채널 ID — 바꾸면 기존 채널 설정(사용자 음소거 등)이 분리된다
const monthlyReminderChannelId = 'monthly_reminder';

/// 로컬 알림 스케줄러 추상화 — 테스트에서 fake로 교체 (로컬 알림만, 푸시 서버 없음)
abstract class ReminderScheduler {
  Future<bool> ensurePermissions();

  Future<void> scheduleAll(List<ReminderNotification> notifications);

  Future<void> cancelAll();
}

class LocalNotificationReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // 권한은 유저가 리마인더를 켤 때 요청 (온보딩 무권한 원칙)
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> ensurePermissions() async {
    await _ensureInitialized();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true) ?? true;
    }
    return true;
  }

  @override
  Future<void> scheduleAll(List<ReminderNotification> notifications) async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    for (final notification in notifications) {
      // 절대 시각 기준 1회성 예약이므로 타임존 DB 없이 UTC 변환으로 충분
      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: tz.TZDateTime.from(notification.when, tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            monthlyReminderChannelId,
            notification.channelName,
            channelDescription: notification.channelDescription,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationReminderScheduler(),
);
