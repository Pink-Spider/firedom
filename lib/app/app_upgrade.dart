import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import '../l10n/l10n.dart';
import 'router.dart';

/// 인앱 업데이트 체크 (소프트) — 스토어에 더 새 버전이 있으면 안내만 한다.
///
/// - 스토어 공개 버전 조회만 사용 (재무·개인 데이터 전송 없음, 로컬 우선 원칙 유지)
/// - 강제 아님: "나중에"로 넘어갈 수 있다 (무시=영구 숨김은 비활성)
/// - release 빌드에서만 감싼다 — 디버그/테스트에선 네트워크 조회·다이얼로그 없음
///
/// MaterialApp.builder 안에서 호출되므로 Builder로 Localizations 아래의
/// context를 얻어 현재 UI 언어의 문구를 upgrader에 넘긴다.
Widget wrapWithUpgradeCheck(Widget child) {
  if (!kReleaseMode) return child;
  return Builder(
    builder: (context) => UpgradeAlert(
      navigatorKey: rootNavigatorKey,
      showIgnore: false, // 소프트: 영구 무시 없이 "나중에"만
      upgrader: Upgrader(
        messages: L10nUpgraderMessages(
          context.l10n,
          Localizations.localeOf(context).languageCode,
        ),
        durationUntilAlertAgain: const Duration(days: 3),
      ),
      child: child,
    ),
  );
}

/// 업데이트 안내 문구 — arb(ko·en·ja)에서 가져온다.
///
/// `{{appName}}` 등은 upgrader가 나중에 치환하는 템플릿 토큰이라
/// 그대로 플레이스홀더 값으로 넣는다.
class L10nUpgraderMessages extends UpgraderMessages {
  final AppLocalizations l10n;

  L10nUpgraderMessages(this.l10n, String languageCode)
      : super(code: languageCode);

  @override
  String get title => l10n.upgradeTitle;

  @override
  String get body => l10n.upgradeBody(
        '{{appName}}',
        '{{currentAppStoreVersion}}',
        '{{currentInstalledVersion}}',
      );

  @override
  String get prompt => l10n.upgradePrompt;

  @override
  String get buttonTitleLater => l10n.upgradeLater;

  @override
  String get buttonTitleUpdate => l10n.upgradeUpdate;

  @override
  String get releaseNotes => l10n.upgradeReleaseNotes;
}
