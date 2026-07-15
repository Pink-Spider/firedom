# TestFlight 임시 배포 가이드 (iOS 베타)

지인·베타테스터에게 앱을 임시 배포하는 절차. `flutter run`(개발 기기 직접 설치,
7일 만료)과 달리 **TestFlight는 서명·만료 신경 없이 스토어 경로로** 배포된다.

전제: fvm으로 Flutter 고정 — 모든 명령은 프로젝트 루트에서 `fvm flutter ...`.
서명은 Xcode 자동 서명(팀 `Z53YTTRR32`), 번들 `app.firedom.firedom`.

## 0. 사전 준비 (최초 1회)

- **Apple Developer Program 멤버십** (연 $99) — 팀 `Z53YTTRR32`
- **App Store Connect에 앱 등록**:
  [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps →
  **＋ → New App** → 번들 `app.firedom.firedom`, 앱 이름(파이어덤),
  기본 언어, SKU 입력
- **계약(Agreements, Tax, and Banking)**: 계약 활성화.
  TestFlight 베타만 할 거면 무료 계약이면 되고, 구독까지 팔려면
  Paid Apps 계약 + 세금/은행 정보도 서명해야 상품이 활성화된다.

## 1. 버전·빌드 번호 올리기 ★

`pubspec.yaml`의 `version: 0.1.0+1` — `0.1.0`은 사용자 버전, `+1`은 빌드 번호.

- **업로드할 때마다 빌드 번호(`+N`)를 반드시 +1** 한다 (같은 번호는 스토어가 거부).
- 사용자 버전은 의미 있는 릴리스마다 올린다 (0.1.1, 0.2.0 …).
- 예: `version: 0.1.0+2`

## 2. 빌드 (아카이브)

```bash
# CLI — build/ios/ipa/*.ipa 생성
fvm flutter build ipa
```

또는 Xcode(자동 서명이라 더 매끄러움):

```bash
open ios/Runner.xcworkspace
# 상단 타깃을 "Any iOS Device" → 메뉴 Product ▸ Archive
```

- 첫 아카이브는 pod install·컴파일 포함 수 분.

## 3. 업로드

- **Xcode Organizer**(아카이브 후 자동으로 열림):
  **Distribute App → App Store Connect → Upload**
- 또는 **Transporter** 앱(Mac App Store 무료)에 `.ipa`를 드래그해 업로드
- CLI로도 가능하지만(altool/notarytool + 앱 암호) Organizer/Transporter가 쉬움

## 4. App Store Connect → TestFlight 탭

- 업로드 후 빌드가 **"처리 중"** → 5~30분 뒤 사용 가능
- **수출 규정(암호화) 질문** 답변 (아래 §6 주의)
- 테스터 추가:
  - **내부 테스터**(App Store Connect 팀원, 최대 100명): **즉시**, 심사 없음
    → 지인 테스트엔 이게 가장 빠름
  - **외부 테스터**(최대 10,000명, 이메일/공개 링크): 첫 빌드는
    **Beta App Review**(보통 하루 내) 필요

## 5. 테스터가 받는 법

아이폰에 **TestFlight 앱**(App Store) 설치 → 초대 수락(이메일/링크) → 설치.
이후 새 빌드는 **TestFlight에서 자동 업데이트**된다.

## 6. 주의점 (Gotchas)

- **빌드 번호 유일**: 재업로드 시 반드시 증가(§1).
- **암호화 컴플라이언스**: 이 앱은 백업에 AES-256을 써서 업로드마다 암호화
  질문이 뜬다. 표준 암호화로 사용자 자기 데이터를 보호하는 경우는 보통
  **면제 대상**이라, `ios/Runner/Info.plist`에
  `ITSAppUsesNonExemptEncryption`를 `false`로 넣으면 매 업로드 질문을 스킵한다
  (면제 해당 여부만 확인 후 적용).
- **SPM/CocoaPods 경고**는 빌드에 영향 없음.
- **데이터 보존**: 로컬 SQLite + 스키마 마이그레이션이라 업데이트해도 기록·계획
  유지. 단 앱 삭제 시 로컬 데이터 소멸(→ 설정의 백업/복원 사용).

## 7. 정식 출시와의 관계

- TestFlight 빌드를 그대로 **App Store 심사 제출**로 승격할 수 있다
  (같은 빌드를 "App Store" 배포로).
- 한국 사용자는 정식 출시 시 App Store Connect에 등록한 **원화(₩) 가격**으로
  자동 결제된다 (RevenueCat/스토어가 지역 통화 처리).

## 8. RevenueCat 키 주의 (결제 테스트 시)

TestFlight 빌드에 결제를 붙여 테스트하려면 `revenuecat.json`(git 제외)에 키를
넣고 `--dart-define-from-file`로 주입한다. **Test Store 키를 정식 출시 빌드에는
넣지 말 것** — 프로덕션은 `appl_`/`goog_` 키. (자세한 건 `revenuecat.json.example`)

## 9. QA용 IPA 빌드 (테스터가 결제 없이 프리미엄 테스트) ★

테스터가 **결제 없이 유료 게이트를 켜서** 확인할 수 있는 빌드. 두 플래그를
넣어 IPA를 만든다:

```bash
# 1) 빌드번호 먼저 +1 (pubspec.yaml: version: 0.1.0+1 → +2 …)
# 2) QA 플래그 + RevenueCat 키 주입해서 빌드
fvm flutter build ipa \
  --dart-define-from-file=revenuecat.json \
  --dart-define=FIREDOM_QA=true
```
→ `build/ios/ipa/firedom.ipa` 생성 → Transporter/Organizer로 업로드(§3).

- **`--dart-define=FIREDOM_QA=true`**: 설정 화면에 "프리미엄 시뮬레이션 (QA)"
  토글이 나타나 결제 없이 유료 기능을 테스트할 수 있다.
- **`--dart-define-from-file=revenuecat.json`**: RevenueCat 키를 주입해 결제
  흐름(Test Store)까지 테스트. 키가 없거나 비면 스텁으로 폴백(QA 토글만 동작).
- QA 토글 없이 순수 릴리스로 만들려면 두 플래그를 빼고 `fvm flutter build ipa`.

⚠️ **이 QA 빌드(QA 토글·Test Store 키 포함)는 TestFlight 베타 전용 —
App Store 정식 심사/출시로 승격하지 말 것.** 정식 출시는 플래그 없이,
프로덕션 RevenueCat 키(`appl_`/`goog_`)로 다시 빌드한다.
