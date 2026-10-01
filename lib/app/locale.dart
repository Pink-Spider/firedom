import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/providers.dart';
import '../data/repositories/settings_store.dart';
import '../l10n/l10n.dart';

/// UI 언어 설정 — settings 테이블. null이면 기기 언어를 따른다 (MaterialApp 기본 해석).
final localeProvider = StreamProvider<Locale?>(
  (ref) => ref
      .watch(settingsStoreProvider)
      .watch<String>(SettingKeys.locale)
      .map((code) => code == null ? null : Locale(code)),
);

/// 설정 화면의 언어 선택지 (null = 시스템)
const selectableLocales = [null, ...AppLocalizations.supportedLocales];
