import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'router.dart';

/// 인앱 업데이트 체크 (소프트) — 스토어에 더 새 버전이 있으면 안내만 한다.
///
/// - 스토어 공개 버전 조회만 사용 (재무·개인 데이터 전송 없음, 로컬 우선 원칙 유지)
/// - 강제 아님: "나중에"로 넘어갈 수 있다 (무시=영구 숨김은 비활성)
/// - release 빌드에서만 감싼다 — 디버그/테스트에선 네트워크 조회·다이얼로그 없음
Widget wrapWithUpgradeCheck(Widget child) {
  if (!kReleaseMode) return child;
  return UpgradeAlert(
    navigatorKey: rootNavigatorKey,
    showIgnore: false, // 소프트: 영구 무시 없이 "나중에"만
    upgrader: Upgrader(
      messages: _KoUpgraderMessages(),
      durationUntilAlertAgain: const Duration(days: 3),
    ),
    child: child,
  );
}

/// 업데이트 안내 문구 (한국어)
class _KoUpgraderMessages extends UpgraderMessages {
  _KoUpgraderMessages() : super(code: 'ko');

  @override
  String get title => '업데이트가 있어요';

  @override
  String get body =>
      '{{appName}}의 새 버전 {{currentAppStoreVersion}}이 나왔어요. '
      '지금 버전은 {{currentInstalledVersion}}이에요.';

  @override
  String get prompt => '지금 업데이트할까요?';

  @override
  String get buttonTitleLater => '나중에';

  @override
  String get buttonTitleUpdate => '업데이트';

  @override
  String get releaseNotes => '이번 업데이트 내용';
}
