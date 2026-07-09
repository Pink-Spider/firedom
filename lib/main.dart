import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/bootstrap.dart';
import 'data/db/database.dart';
import 'data/db/providers.dart';
import 'data/notifications/reminder_scheduler.dart';
import 'data/prefs.dart';
import 'data/reminders.dart';
import 'features/lock/app_lock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(driftDatabase(name: 'firedom'));
  final bootstrap = await bootstrapApp(db, prefs);

  // 리마인더 재예약 (미기록 월 기준 최신화) — 실패해도 기동을 막지 않는다
  await rescheduleReminders(
    db: db,
    scheduler: LocalNotificationReminderScheduler(),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        hasActivePlanAtLaunchProvider.overrideWithValue(
            bootstrap.hasActivePlan),
        biometricLockAtLaunchProvider.overrideWithValue(
            bootstrap.biometricLockEnabled),
      ],
      child: const FiredomApp(),
    ),
  );
}
