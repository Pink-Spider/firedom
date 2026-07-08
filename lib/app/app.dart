import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'theme.dart';

class FiredomApp extends StatelessWidget {
  const FiredomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '파이어덤',
      theme: buildTheme(),
      routerConfig: router,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
