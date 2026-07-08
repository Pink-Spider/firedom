import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/bootstrap.dart';
import 'data/db/database.dart';
import 'data/db/providers.dart';
import 'data/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(driftDatabase(name: 'firedom'));
  final hasPlan = await bootstrapApp(db, prefs);
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        hasActivePlanAtLaunchProvider.overrideWithValue(hasPlan),
      ],
      child: const FiredomApp(),
    ),
  );
}
