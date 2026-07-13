import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/providers.dart';
import '../data/repositories/settings_store.dart';

const _seedColor = Color(0xFFE8590C);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _seedColor);
  return _themeFrom(scheme);
}

/// S10 다크 테마 — 라이트와 같은 시드의 M3 다크 스킴 (Figma 다크 토큰 기준)
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );
  return _themeFrom(scheme);
}

ThemeData _themeFrom(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

/// 설정 문자열('system'|'light'|'dark') ↔ [ThemeMode]
ThemeMode themeModeFromName(String? name) => switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

String themeModeName(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

/// 화면 테마 설정 (S10) — 기본값은 시스템 추종
final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref
      .watch(settingsStoreProvider)
      .watch<String>(SettingKeys.themeMode)
      .map(themeModeFromName),
);
