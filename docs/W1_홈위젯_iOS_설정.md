# W1 홈 위젯 — iOS 설정 가이드

> **현황 (2026-09-08)**: iOS 위젯은 **v1.0에 포함되지 않았다.** 아래 Xcode 설정이
> 미완이라 익스텐션이 빌드에 들어가지 않았고(IPA에 `PlugIns/` 없음), 그래서
> App Store 설명에서 위젯 문구를 뺐다. Android 위젯은 정상 동작한다.
> v1.1(`epic/v1.1` 브랜치)에서 붙인다.
>
> **Apple Developer 사전 작업은 완료됐다** — 아래 §0 참고. 남은 건 Xcode 작업뿐이다.

## 0. Apple Developer 등록 현황 ✅ 완료

| 항목 | 값 | 상태 |
|---|---|---|
| 메인 앱 App ID | `app.firedom.firedom` | App Groups 활성 + 그룹 배정(1) |
| 위젯 App ID | `app.firedom.firedom.FiredomWidget` | App Groups 활성 + 그룹 배정(1) |
| App Group | `group.app.firedom.firedom` | 생성됨 (Firedom Widget Group) |

App Group 식별자는 `lib/data/home_widget_sync.dart`의 `appGroupId` 상수와
**정확히 일치해야 한다**. 위젯 App ID의 마지막 마디(`FiredomWidget`)는 같은 파일의
`iOSName: 'FiredomWidget'` 및 Xcode 타겟 Product Name과 일치해야 한다.

> capability를 켜면서 기존 프로비저닝 프로파일이 무효화됐다. Xcode 자동 서명이라
> 다음 빌드 때 자동 재생성된다. 이미 업로드된 심사용 빌드에는 영향이 없다.


Android 위젯은 코드만으로 동작하지만, iOS WidgetKit은 **Xcode에서 Extension
타겟을 수동으로 추가**해야 한다. 아래 순서대로 1회 설정하면 된다.

## 1. Widget Extension 타겟 추가

1. `ios/Runner.xcworkspace`를 Xcode로 연다
2. File → New → Target… → **Widget Extension** 선택
3. Product Name: `FiredomWidget` (Dart의 `iOSName`과 일치해야 함)
4. "Include Configuration App Intent" 체크 해제 → Finish
5. Activate scheme 물음에는 Cancel

## 2. 생성된 템플릿 파일 교체

- Xcode가 만든 `FiredomWidget/FiredomWidget.swift` 내용을
  이 저장소의 `ios/FiredomWidget/FiredomWidget.swift`로 교체한다

## 3. App Group 설정 (앱 ↔ 위젯 데이터 공유)

1. Runner 타겟 → Signing & Capabilities → **+ App Groups**
   - `group.app.firedom.firedom` 추가
2. FiredomWidget 타겟에도 동일하게 App Groups 추가
   - 같은 `group.app.firedom.firedom` 체크
3. Apple Developer 계정에서 App Group 등록이 필요할 수 있다

## 4. 배포 타겟

- FiredomWidget 타겟의 iOS Deployment Target을 Runner와 같거나
  낮게(예: 17.0) 설정

## 확인

- 앱에서 스냅샷을 저장하면 `syncHomeWidget()`이 App Group
  UserDefaults(`dday_text`/`progress`/`deviation_text`)를 갱신하고
  위젯 타임라인을 리로드한다
- 위젯에는 D-day·진행률·편차 배지만 표시된다 — **금액은 절대 노출하지
  않는다** (PRD W1)

## 6. 설정 후 검증

```bash
fvm flutter build ipa --dart-define-from-file=revenuecat.prod.json
T=$(mktemp -d); unzip -q build/ios/ipa/firedom.ipa -d "$T"
ls "$T"/Payload/Runner.app/PlugIns/          # FiredomWidget.appex 가 보여야 한다
codesign -d --entitlements - "$T"/Payload/Runner.app 2>/dev/null | grep -a application-groups
```

`PlugIns/`에 `.appex`가 있고 entitlement에 `group.app.firedom.firedom`이 찍혀야
위젯이 실제로 포함된 것이다. 이게 확인돼야 스토어 문구에 위젯을 다시 넣는다
(`docs/스토어_등록_문구.md`).
