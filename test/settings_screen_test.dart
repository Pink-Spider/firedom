import 'package:firedom/core/ym.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/db/providers.dart';
import 'package:firedom/data/entitlements.dart';
import 'package:firedom/data/notifications/reminder_scheduler.dart';
import 'package:firedom/data/reminders.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
import 'package:firedom/features/lock/biometric.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class FakeScheduler implements ReminderScheduler {
  bool permissionsGranted = true;
  int permissionRequests = 0;
  int cancelCount = 0;
  final List<List<ReminderNotification>> scheduledBatches = [];

  @override
  Future<bool> ensurePermissions() async {
    permissionRequests++;
    return permissionsGranted;
  }

  @override
  Future<void> scheduleAll(List<ReminderNotification> notifications) async {
    scheduledBatches.add(notifications);
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
  }
}

/// RevenueCat이 구성된 것처럼 고객 ID를 돌려주는 페이크
class FakeEntitlementService extends EntitlementService {
  FakeEntitlementService(super.store);

  @override
  Future<String?> customerId() async => r'$RCAnonymousID:test-1234';
}

class FakeAuthenticator implements BiometricAuthenticator {
  bool supported = true;
  bool result = true;
  int attempts = 0;

  @override
  Future<bool> get isSupported async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    attempts++;
    return result;
  }
}

const _g1 = PlanInput(
  age0: 35,
  currentAssets: 100000000,
  monthlySaving: 2000000,
  realReturnBp: 400,
  monthlySpendRetire: 3000000,
);

Future<void> seedPlan(AppDatabase db) async {
  final ym = nowYm();
  await PlanRepository(db).createPlan(
    input: _g1,
    birthYm: birthYmFromAge(_g1.age0, ym),
    startedYm: ym,
  );
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
}

void main() {
  appTest('S10 리마인더: 켜면 권한 요청 후 3개월치 예약 (말일 20:00 기본)', (tester) async {
    final scheduler = FakeScheduler();
    final db = await pumpApp(
      tester,
      seed: (db) async => seedPlan(db),
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    );
    await openSettings(tester);

    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(scheduler.scheduledBatches, hasLength(1));
    final batch = scheduler.scheduledBatches.last;
    expect(batch, hasLength(3));
    final expected = upcomingReminderTimes(
      settings: const ReminderSettings(enabled: true),
      now: DateTime.now(),
      recordedYms: {},
    );
    expect(batch.first.when, expected.first);
    expect(
        await SettingsStore(db).get<bool>(SettingKeys.reminderEnabled), isTrue);

    // 날짜 변경: 매월 1일 → 재예약, 일자 반영
    await tester.tap(find.byKey(const ValueKey('reminder-day-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매월 1일').last);
    await tester.pumpAndSettle();

    expect(scheduler.scheduledBatches.last.first.when.day, 1);
    expect(await SettingsStore(db).get<int>(SettingKeys.reminderDay), 1);
  });

  appTest('S10 리마인더: 권한 거부 시 켜지지 않음', (tester) async {
    final scheduler = FakeScheduler()..permissionsGranted = false;
    final db = await pumpApp(
      tester,
      seed: (db) async => seedPlan(db),
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    );
    await openSettings(tester);

    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();

    expect(find.textContaining('알림 권한이 필요해요'), findsOneWidget);
    expect(scheduler.scheduledBatches, isEmpty);
    expect(await SettingsStore(db).get<bool>(SettingKeys.reminderEnabled),
        isNull);
  });

  appTest('S10 리마인더: 기록 저장 시 이번 달 제외하고 재예약 (조건부 발송)', (tester) async {
    final scheduler = FakeScheduler();
    await pumpApp(
      tester,
      seed: (db) async {
        await seedPlan(db);
        final store = SettingsStore(db);
        await store.set(SettingKeys.reminderEnabled, true);
        await SnapshotRepository(db).ensureDefaultAccounts();
      },
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    );

    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('amount-예금')), '10000000');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('저장'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(scheduler.scheduledBatches, isNotEmpty);
    final expected = upcomingReminderTimes(
      settings: const ReminderSettings(enabled: true),
      now: DateTime.now(),
      recordedYms: {nowYm()}, // 이번 달 기록됨 → 다음 달부터
    );
    expect(scheduler.scheduledBatches.last.first.when, expected.first);
  });

  appTest('S10 생체인증: 설정에서 켜기 (인증 성공 필요)', (tester) async {
    final authenticator = FakeAuthenticator();
    final db = await pumpApp(
      tester,
      seed: (db) async => seedPlan(db),
      overrides: [
        biometricAuthenticatorProvider.overrideWithValue(authenticator),
      ],
    );
    await openSettings(tester);

    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('biometric-switch')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('biometric-switch')));
    await tester.pumpAndSettle();

    expect(authenticator.attempts, 1);
    expect(await SettingsStore(db).get<bool>(SettingKeys.biometricLock),
        isTrue);
  });

  appTest('S10 생체인증: 잠금 상태로 기동 → 인증 후 해제', (tester) async {
    final authenticator = FakeAuthenticator()..result = false;
    await pumpApp(
      tester,
      seed: (db) async {
        await seedPlan(db);
        await SettingsStore(db).set(SettingKeys.biometricLock, true);
      },
      overrides: [
        biometricAuthenticatorProvider.overrideWithValue(authenticator),
      ],
    );

    // 잠금 화면이 앱 내용을 가린다
    expect(find.text('파이어덤이 잠겨 있어요'), findsOneWidget);
    expect(find.textContaining('재정적 자유까지'), findsNothing);

    // 인증 실패 → 여전히 잠김
    await tester.tap(find.text('잠금 해제'));
    await tester.pumpAndSettle();
    expect(find.text('파이어덤이 잠겨 있어요'), findsOneWidget);

    // 인증 성공 → 홈 진입
    authenticator.result = true;
    await tester.tap(find.text('잠금 해제'));
    await tester.pumpAndSettle();
    expect(find.textContaining('재정적 자유까지'), findsOneWidget);
  });

  appTest('S10 구독: 고객 ID 타일 — 탭하면 클립보드 복사', (tester) async {
    final copied = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String?);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpApp(
      tester,
      seed: (db) async => seedPlan(db),
      overrides: [
        entitlementServiceProvider.overrideWith(
          (ref) => FakeEntitlementService(ref.watch(settingsStoreProvider)),
        ),
      ],
    );
    await openSettings(tester);

    final tile = find.byKey(const ValueKey('customer-id-tile'));
    await tester.scrollUntilVisible(tile, 200);
    expect(find.textContaining(r'$RCAnonymousID:test-1234'), findsOneWidget);

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(copied, [r'$RCAnonymousID:test-1234']);
    expect(find.text('고객 ID를 복사했어요'), findsOneWidget);
  });

  appTest('S10 구독: RevenueCat 미구성(스텁)이면 고객 ID 타일 없음', (tester) async {
    await pumpApp(tester, seed: (db) async => seedPlan(db));
    await openSettings(tester);
    expect(find.byKey(const ValueKey('customer-id-tile')), findsNothing);
  });
}
