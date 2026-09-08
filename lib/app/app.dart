import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lock/app_lock.dart';
import 'app_upgrade.dart';
import 'router.dart';
import 'theme.dart';

class FiredomApp extends ConsumerWidget {
  const FiredomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockedProvider);
    final themeMode =
        ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return MaterialApp.router(
      title: '파이어덤',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 생체인증 앱 잠금 (S10): 해제 전까지 전체 화면을 가린다.
      // 잠금 해제 상태에선 인앱 업데이트 체크(소프트)로 감싼다.
      builder: (context, child) => locked
          ? const AppLockScreen()
          : wrapWithUpgradeCheck(child!),
    );
  }
}
