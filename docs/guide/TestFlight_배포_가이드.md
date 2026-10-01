# 배포 가이드 — TestFlight 베타 · App Store · Google Play

§1~§9는 지인·베타테스터용 **TestFlight 임시 배포**(`flutter run`의 7일 만료 없이
스토어 경로로 배포), §10~§12는 **정식 출시**(App Store / Google Play) 절차다.
*파일명은 TestFlight로 시작하지만 정식 출시까지 다룬다.*

전제: fvm으로 Flutter 고정 — 모든 명령은 프로젝트 루트에서 `fvm flutter ...`.
서명은 iOS Xcode 자동 서명(팀 `Z53YTTRR32`), Android는 업로드 키스토어
(`android/key.properties`). 번들/패키지 `app.firedom.firedom`.

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

## 10. 정식 출시(App Store 심사 제출)용 빌드 ★

프로덕션 키는 `revenuecat.prod.json`(git 미포함)에 있다. QA 플래그 없이 빌드:

```bash
# 빌드번호 확인 후 (TestFlight에 이미 올라간 번호면 +1)
fvm flutter build ipa --dart-define-from-file=revenuecat.prod.json
```
→ `build/ios/ipa/firedom.ipa` → Transporter/Organizer로 업로드(§3).

- RevenueCat 공개 SDK 키는 iOS `appl_...`, Android `goog_...` 둘 다
  `revenuecat.prod.json`에 들어 있다(2026-09-07 발급).

## 11. Android 정식 출시 (Google Play) ★

```bash
# 빌드번호는 iOS와 공유한다 (pubspec.yaml의 +N). Play는 versionCode 중복을 거부한다
fvm flutter build appbundle --dart-define-from-file=revenuecat.prod.json
```
→ `build/app/outputs/bundle/release/app-release.aab`

**서명**: `android/key.properties`가 있으면 업로드 키스토어로 서명된다. 없으면
디버그 서명으로 폴백하므로 Play가 거부한다. 빌드 후
`keytool -printcert -jarfile <aab>`로 `CN=Firedom`인지 확인할 것.

업로드·제출 순서 (Play Console):

1. **테스트 및 출시 → 프로덕션 → 새 버전 만들기** — AAB 드래그 업로드.
   업로드가 끝날 때까지 페이지를 벗어나지 말 것 (나가면 취소된다)
2. 출시명·출시 노트(`<ko-KR>` 태그 안에) 입력 → **다음** → **저장**
3. **국가/지역 탭에서 배포 지역 선택** — 기본값이 0개라 안 하면 제출이 막힌다.
   파이어덤은 **대한민국만**
4. **스토어 등록정보**는 파란 **「저장」**까지 눌러야 한다. 「임시보관함에 저장」만
   하면 출시 검토에서 *"전체 설명을 추가하세요"* 오류가 난다
5. **게시 개요 → 검토를 위해 변경사항 N개 제출**

### 걸리기 쉬운 지점

- **구독 상품은 AAB를 한 번 올린 뒤에야 만들 수 있다.** 그전에는 정기 결제 화면에
  「새 APK 업로드」만 보이고 생성 버튼이 없다
- 구독은 **기본 요금제를 활성화**해야 판매된다. 무료 체험은 기본 요금제에 붙는
  별도 「혜택」이고, 이것도 따로 활성화해야 한다
- 무료 체험 자격 기준은 **"구독한 적 없음"(앱 단위)** 로 잡는다. "이 구독을 이용한
  적 없음"(상품 단위)으로 두면 연간·월간에서 체험을 두 번 받을 수 있다
- 검토가 시작된 뒤 국가/지역을 바꿔도 **검토 중인 배치에는 반영되지 않는다.**
  `변경사항 삭제`로 회수 → 수정 → 재제출해야 한다 (App Store는 배포 지역이
  버전 심사와 독립적이라 심사 대기 중에도 그냥 바꿀 수 있다 — 스토어별로 다르다)

## 12. 릴리스 체크리스트

- [ ] `fvm flutter analyze` / `fvm flutter test` 통과
- [ ] `pubspec.yaml` 빌드번호 +1 (iOS·Android 공유)
- [ ] **스토어 문구의 모든 기능 주장을 빌드 산출물로 검증** (아래 §13)
- [ ] 스크린샷이 최신 UI인지 (`store_assets/screenshots/`)
- [ ] 배포 지역: 다국어 빌드(ko·en·ja) 이전 버전은 **대한민국만**. 다국어 빌드부터는
      `docs/스토어_등록_문구.md` §5-4의 국가 목록 (아래 §14)
- [ ] 다국어 빌드라면 `fvm flutter test test/l10n_smoke_test.dart` 통과 (en·ja 화면에 한글 누락 없음)
- [ ] 출시 후 RevenueCat 마무리 — 자격증명 재검증, Google developer notifications 연결,
      실기기 결제 1건 확인


## 13. 스토어 문구 검증 — 기획서가 아니라 빌드로 확인한다 ★

v1.0 준비 중 **같은 유형의 사고가 네 번** 났다. 전부 원인이 같다 —
문구를 PRD/계획 기준으로 쓰고 실제 빌드와 대조하지 않았다.

| 사고 | 내용 | 결과 |
|---|---|---|
| 미출시 프리미엄 기능 | '시나리오 나란히 비교', '시퀀스 리스크 테스트'를 판매 문구에 기재 | 심사 취소 후 재제출 |
| 전 세계 배포 | 한국어 단일 앱을 177개국으로 설정 | Play 심사 배치 폐기 |
| iOS 홈 위젯 | Android만 동작하는데 양쪽 설명에 기재 | 설명 수정 (이후 v1.1에서 실제 구현) |
| 구독 필수 링크 누락 | 이용약관(EULA) 링크가 앱·메타데이터 양쪽에 없음 | **빌드 6 리젝** (3.1.2(c)) |

**규칙: 설명의 기능 한 줄마다 근거를 빌드에서 찾는다.** 못 찾으면 문구에서 뺀다.

```bash
# 1) 페이월에 올린 기능은 전부 지금 동작해야 한다 (미출시 배지 메커니즘은 제거됨)
grep -n "_FeatureRow(" lib/features/paywall/paywall_sheet.dart

# 1-1) 구독 앱 필수 링크 — 이용약관(EULA)·개인정보가 앱 안에 있고 실제로 열리는지
grep -n "paywallTermsUrl\|paywallPrivacyUrl\|launchUrl" \
  lib/features/paywall/paywall_sheet.dart

# 2) iOS 익스텐션(위젯 등)이 실제 IPA에 들어갔는지
T=$(mktemp -d); unzip -q build/ios/ipa/firedom.ipa -d "$T"
ls "$T"/Payload/Runner.app/PlugIns/ 2>/dev/null || echo "익스텐션 없음"
codesign -d --entitlements - "$T"/Payload/Runner.app 2>/dev/null | grep -a application-groups

# 3) Android 위젯이 실제 AAB에 들어갔는지
unzip -l build/app/outputs/bundle/release/app-release.aab | grep -i firedom_widget

# 4) 나머지 기능 주장은 코드에서 확인 (--include는 반드시 따옴표로 — zsh 글로빙 주의)
grep -rn "국민연금" lib/ --include='*.dart'
```

**주의**: `grep -rn ... --include=*.dart`를 따옴표 없이 쓰면 zsh가 글로빙에 실패해
*"못 찾음"이 거짓으로 뜬다.* 실제로 이 때문에 멀쩡한 기능을 미구현으로 오판한 적이 있다.
없다는 결론을 내리기 전에 명령이 제대로 돌았는지부터 의심할 것.

**릴리스 바이너리에서 직접 확인**하고 싶으면 Dart 문자열의 저장 방식을 알아야 한다.
ASCII 문자열(URL 등)은 그대로 박히지만 **한글은 UTF-16LE**(Dart TwoByteString)라
`strings`/`grep`으로는 안 잡힌다 — 없다고 오판하기 쉬운 지점이다.

```bash
python3 - <<'EOF'
p='<IPA 압축 해제 경로>/Payload/Runner.app/Frameworks/App.framework/App'
b=open(p,'rb').read()
for s in ['이용약관','개인정보 처리방침']:
    print(s, b.count(s.encode('utf-16-le')))   # utf-8로 세면 0이 나온다
print('EULA URL', b.count(b'apple.com/legal/internet-services/itunes/dev/stdeula/'))
EOF
```

## 14. 글로벌 배포 절차 — 다국어 빌드부터 ★

앱이 ko·en·ja 3개 언어와 KRW/USD/JPY 통화를 지원하는 빌드가 되기 전에는 **절대 국가를 넓히지
않는다** (§13의 "전 세계 배포" 사고 참조 — 한국어 단일 앱을 177개국에 풀었다가 폐기됐다).

### 14-1. 빌드에서 확인할 것

```bash
# 언어 리소스가 전부 들어갔는지
python3 tool/merge_l10n.py && fvm flutter gen-l10n && fvm flutter analyze
fvm flutter test test/l10n_smoke_test.dart test/core/currency_test.dart

# iOS: 앱 이름·Face ID 문구의 언어별 리소스가 IPA에 들어갔는지
T=$(mktemp -d); unzip -q build/ios/ipa/firedom.ipa -d "$T"
ls "$T"/Payload/Runner.app/*.lproj                  # ko.lproj en.lproj ja.lproj
ls "$T"/Payload/Runner.app/PlugIns/FiredomWidgetExtension.appex/*.lproj
plutil -p "$T"/Payload/Runner.app/Info.plist | grep -i "DisplayName\|NonExempt"

# Android: 언어별 strings.xml이 AAB에 들어갔는지 (resources.pb 안에 values-ko/values-ja)
unzip -l build/app/outputs/bundle/release/app-release.aab | grep -i "values-ko\|values-ja" || echo "resources.pb에 포함 — bundletool로 확인"
```

실기기 확인: 기기 언어를 영어·일본어로 바꾸고 온보딩 → 홈 → 시뮬레이션 → 기록 → 설정 → 페이월을
한 바퀴 돈다. 홈 위젯과 월간 리마인더 알림 문구도 기기 언어를 따르는지 본다.
온보딩에서 통화를 USD로 고르면 금액 입력이 달러 단위(센트 저장)로 바뀌고, 차트 축이 `$100K`
단위가 되는지 확인한다.

### 14-2. 스토어 콘솔 순서

1. **등록정보 언어 추가** — ASC: 앱 정보 → 현지화 추가(en-US, ja). Play: 스토어 설정 → 기본 언어
   유지(ko-KR) + 번역 추가(en-US, ja-JP). 문구는 `docs/스토어_등록_문구.md` §5.
2. **스크린샷** — 언어별 세트 업로드 (en: USD 데이터, ja: JPY 데이터).
3. **가격** — 구독 상품은 그대로, 국가별 가격은 자동 환산 확인 후 필요 시 수동 조정 (§5-4).
   RevenueCat은 상품 ID가 같으니 변경 없음.
4. **개인정보 처리방침·지원 URL** — 영어·일본어 페이지가 올라간 뒤에 국가를 연다.
5. **국가 추가** — ASC: 가격 및 배포 가능 여부 → 국가 선택. Play: 프로덕션 트랙 → 국가/지역.
   1차는 §5-4 목록만. 양쪽 모두 **새 빌드 없이** 국가만 추가할 수 있지만, 다국어 빌드가
   이미 심사 통과한 상태여야 한다.
6. **리뷰 노트** — 영어 리뷰 노트(§5-1) 추가. 로그인 불필요·계좌 연동 없음을 명시.
7. 출시 후 `docs/스토어_등록_문구.md` 공용 URL의 "`/us/` 404" 주의와 CLAUDE.md의 배포 지역 항목을 갱신한다.

