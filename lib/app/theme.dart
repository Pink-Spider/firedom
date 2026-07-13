import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/providers.dart';
import '../data/repositories/settings_store.dart';

const _seedColor = Color(0xFFE8590C);

/// Figma 디자인 토큰과 정확히 일치시키기 위해, fromSeed로 완전한 M3 스킴을
/// 만든 뒤 Figma에서 지정한 색 토큰(`Firedom / Color` 컬렉션)으로 덮어쓴다.
/// 토큰 미지정 항목(onSecondary 등)은 fromSeed 값을 그대로 둔다.

ThemeData buildTheme() => _themeFrom(_lightScheme());

/// S10 다크 테마 — Figma 다크 모드 토큰과 일치
ThemeData buildDarkTheme() => _themeFrom(_darkScheme());

ColorScheme _lightScheme() =>
    ColorScheme.fromSeed(seedColor: _seedColor).copyWith(
      primary: const Color(0xFF9C4A0E),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFDBC7),
      onPrimaryContainer: const Color(0xFF341100),
      secondary: const Color(0xFF765847),
      secondaryContainer: const Color(0xFFFFDBC7),
      onSecondaryContainer: const Color(0xFF2B1708),
      tertiary: const Color(0xFF616134),
      tertiaryContainer: const Color(0xFFE7E6AE),
      onTertiaryContainer: const Color(0xFF1D1D00),
      error: const Color(0xFFBA1A1A),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFFFF8F5),
      onSurface: const Color(0xFF221A14),
      surfaceContainerLow: const Color(0xFFFDF1EA),
      surfaceContainer: const Color(0xFFF7EBE3),
      surfaceContainerHigh: const Color(0xFFF1E5DD),
      surfaceContainerHighest: const Color(0xFFEDE0D5),
      onSurfaceVariant: const Color(0xFF52443B),
      outline: const Color(0xFF85736A),
      outlineVariant: const Color(0xFFD7C3B8),
      inverseSurface: const Color(0xFF382E28),
      onInverseSurface: const Color(0xFFFFEDE2),
    );

ColorScheme _darkScheme() => ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFFFB68A),
      onPrimary: const Color(0xFF542100),
      primaryContainer: const Color(0xFF703614),
      onPrimaryContainer: const Color(0xFFFFDBC7),
      secondary: const Color(0xFFE6BEA8),
      secondaryContainer: const Color(0xFF5D4231),
      onSecondaryContainer: const Color(0xFFFFDBC7),
      tertiary: const Color(0xFFCACA8F),
      tertiaryContainer: const Color(0xFF494A20),
      onTertiaryContainer: const Color(0xFFE7E6AE),
      error: const Color(0xFFFFB4AB),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: const Color(0xFF1A120D),
      onSurface: const Color(0xFFF0DFD5),
      surfaceContainerLow: const Color(0xFF221A14),
      surfaceContainer: const Color(0xFF271E18),
      surfaceContainerHigh: const Color(0xFF322821),
      surfaceContainerHighest: const Color(0xFF3D322A),
      onSurfaceVariant: const Color(0xFFD7C3B8),
      outline: const Color(0xFF9F8D82),
      outlineVariant: const Color(0xFF52443B),
      inverseSurface: const Color(0xFFF0DFD5),
      onInverseSurface: const Color(0xFF382E28),
    );

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
