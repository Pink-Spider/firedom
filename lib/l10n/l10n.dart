import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../data/repositories/settings_store.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.key` 접근자. 화면 문구는 전부 arb(ko 템플릿, en·ja)로 관리한다.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 설정의 언어 코드(없으면 기기 언어)를 지원 언어로 해석한다.
/// 미지원 언어는 첫 항목(ko)으로 — MaterialApp의 기본 해석과 같은 결과
Locale resolveLocale(String? settingCode) {
  final wanted =
      settingCode != null ? Locale(settingCode) : PlatformDispatcher.instance.locale;
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == wanted.languageCode) return supported;
  }
  return AppLocalizations.supportedLocales.first;
}

/// BuildContext가 없는 곳(로컬 알림 문구, 홈 위젯 페이로드)에서 쓰는 문구 묶음
Future<AppLocalizations> l10nFromSettings(SettingsStore store) async =>
    lookupAppLocalizations(
        resolveLocale(await store.get<String>(SettingKeys.locale)));
