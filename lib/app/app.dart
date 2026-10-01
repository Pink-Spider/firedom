import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lock/app_lock.dart';
import '../l10n/l10n.dart';
import 'app_upgrade.dart';
import 'locale.dart';
import 'router.dart';
import 'theme.dart';

class FiredomApp extends ConsumerWidget {
  const FiredomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockedProvider);
    final themeMode =
        ref.watch(themeModeProvider).value ?? ThemeMode.system;
    // 언어: 설정값이 있으면 고정, 없으면(null) 기기  ㅑ언어 → 미지원이면 supportedLocales 첫 항목(ko)
    final locale = ref.watch(localeProvider).value;
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
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
