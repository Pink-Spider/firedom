# W1 홈 위젯 — iOS 설정 가이드

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
