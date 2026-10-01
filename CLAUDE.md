# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Firedom (파이어덤)

한국형 FIRE(조기은퇴) 시뮬레이터 앱. 핵심 루프: 목표 설계 → 시뮬레이션(계획 궤도) → 월 1회 자산 스냅샷 기록 → 계획 vs 실제 궤도 비교.

상세 기획은 `docs/PRD_FIRE시뮬레이터_MVP.md`(화면 단위 스펙), `docs/경쟁분석_FIRE재무설계앱.md`, `docs/Firedom_브랜드_ASO.md` 참조.

## 스택 / 명령어

- Flutter (fvm으로 버전 고정 — `.fvmrc`의 3.44.5, 항상 `fvm flutter ...` 사용)
- 로컬 DB: SQLite(Drift). 서버 없음(MVP는 완전 로컬, 계정 없음)
- 상태 관리 `flutter_riverpod` 3 / 라우팅 `go_router` / 차트 `fl_chart`
- 언어 ko·en·ja (`lib/l10n/`, ko가 템플릿) / 통화 KRW·USD·JPY (`lib/core/currency.dart`)
- 결제: 스토어 IAP + RevenueCat. **entitlement는 `premium` 고정** (`lib/data/entitlements.dart`)
- 번들ID/패키지: `app.firedom.firedom`

```bash
fvm flutter run -d <device>              # 기기 목록: fvm flutter devices
fvm flutter analyze
fvm flutter test                         # 전체
fvm flutter test test/engine             # 엔진 골든 테스트만 (훅이 자동 실행하는 범위)
fvm flutter test test/snapshot_flow_test.dart            # 파일 하나
fvm flutter test test/engine/deterministic_golden_test.dart --plain-name "G1"   # 테스트 하나
fvm dart run build_runner build --delete-conflicting-outputs   # Drift 코드젠 (database.g.dart는 산출물 — 직접 수정 금지)
fvm dart run flutter_launcher_icons      # 앱 아이콘 재생성 (원본 assets/icon/*.svg → png 변환 후)
python3 tool/merge_l10n.py && fvm flutter gen-l10n   # 문구 변경 후: parts/*.json → arb → app_localizations*.dart
```

- RevenueCat 키는 `--dart-define`으로만 주입한다. 키가 없으면 **스텁 모드**로 기동한다
  (구매/복원은 false, 게이트는 settings 캐시만 참조). 로컬 결제 테스트는
  `--dart-define-from-file=revenuecat.json`, 정식 빌드는 `revenuecat.prod.json`
- `--dart-define=FIREDOM_QA=true`를 주면 설정 화면에 결제 없이 프리미엄을 켜는 QA 토글이 생긴다.
  **정식 출시 빌드에는 절대 넣지 말 것**
- 릴리스 빌드: `fvm flutter build ipa --dart-define-from-file=revenuecat.prod.json` /
  `fvm flutter build appbundle --dart-define-from-file=revenuecat.prod.json`
- iOS 서명: Xcode 자동 서명, 팀 `Z53YTTRR32`
- Android 서명: 업로드 키스토어 `android/app/upload-keystore.jks` + `android/key.properties`
  (둘 다 git 제외). `key.properties`가 없으면 릴리스 빌드가 디버그 서명으로 폴백한다 —
  **분실 시 복구 불가라 백업 필수**

## 아키텍처 결정 (변경 시 반드시 논의)

- **로컬 우선, 서버리스**: 재무 데이터는 기기에만 저장. 어떤 네트워크 전송 코드도 추가 금지 (v1.x 동기화 서버는 별도 결정)
- **시뮬레이션 엔진은 순수 Dart 모듈** (`lib/engine/`): Flutter/UI 의존성 금지. 엑셀 검증 기준 케이스와 골든 테스트 유지, 오차 <0.1%
- **동기화 대비 스키마 규칙**: 모든 테이블 UUID PK(auto-increment 금지), `created_at`/`updated_at`, soft delete(`deleted_at`)
- **금액은 정수(통화 최소 단위)**: double/부동소수점으로 금액 표현 금지. 단위는 설정의 통화
  (`SettingKeys.currency`, 없으면 KRW)의 최소 단위 — KRW·JPY는 1원/1엔, USD는 센트. 통화를 바꿔도
  저장값은 환산하지 않는다(단위만 바뀜). 엔진은 통화를 모른다
- **UI 문구는 arb로만**: 화면 파일에 사용자 노출 문자열 리터럴을 두지 않는다. 원본은
  `lib/l10n/parts/*.json`(ko·en·ja 필수), `tool/merge_l10n.py`로 병합 → `fvm flutter gen-l10n`.
  `test/l10n_smoke_test.dart`가 en·ja 화면에 한글이 남으면 실패한다
- 몬테카를로는 Dart isolate에서 실행 (UI 블로킹 금지), 시드 고정 옵션 유지

## 코드 구조와 흐름

레이어는 `engine → data → features` 단방향이다. 엔진은 아무것도 import하지 않고, data는 엔진 모델을
DB 행과 오가게 하며, features는 Riverpod provider로만 data를 본다.

- **`lib/engine/`** — `engine.dart` 배럴 하나로 export. `solvePlan`(결정론 궤도), `runMonteCarlo`,
  `portfolio`(자산군 혼합 수익률/변동성), `tracking`(계획 vs 실제 편차), `milestones`.
  수식·기대값의 출처는 `docs/엔진명세_스키마설계.md`(A·B·R 번호로 코드 주석에서 참조). 골든 테스트
  G1~G6는 명세와 **정확 일치**, 추가 케이스는 오차 <0.1%
- **단위 규약(엔진명세 B0)** — 금액 `int` 원, 비율 `int` bp(400 = 4%), 연월 `int` yyyymm
  (`lib/core/ym.dart`의 `ymAddMonths`/`ymDiffMonths` 사용), 나이는 만 나이. 수익률은 전부 **실질**
  기준이며 명목→실질은 피셔 방정식(`fisherRealBp`)만 허용
- **`lib/data/db/`** — `tables.dart`(스키마, `UuidPk`/`SyncColumns` mixin 필수) → `database.dart`
  (`schemaVersion`, 마이그레이션, 부분 유니크 인덱스는 `customStatement`) → `database.g.dart`(생성).
  스키마를 건드릴 땐 반드시 `drift-migration` 스킬 절차를 따른다. `Settings` 테이블만 k/v 저장소라 규약 예외
- **계획(Plan)은 append-only 리비전** — 수정하면 새 행을 만들고 `revisionGroup`으로 묶는다.
  `isActive`인 행이 현재 계획이며, 리비전 이력은 궤도 차트의 '계획 변경 마커'에 쓰인다
- **Riverpod 주입 패턴** — `databaseProvider`·`hasActivePlanAtLaunchProvider` 등 기동 시점 값은
  `throw UnimplementedError`로 선언하고 `main()`과 테스트 `pumpApp`에서 override한다.
  리포지토리 provider(`lib/data/db/providers.dart`)와 그 위의 `StreamProvider`들이 화면의 데이터 소스
- **프리미엄 게이트** — UI는 항상 `isPremiumProvider`(settings 캐시 `entitlement.premium`)를 보고,
  막힌 동작은 `showPaywallSheet(context)`로 보낸다. RevenueCat `CustomerInfo` 리스너가 캐시를 갱신하므로
  스토어 상태가 진실, 캐시는 사본. 게이트 로직을 추가할 때 RevenueCat을 직접 호출하지 않는다
- **라우팅** — `lib/app/router.dart`. 각 화면은 `static const path`를 갖고, 홈·시뮬레이션·자산은
  `ShellRoute`(하단 탭), 기록·설정·온보딩은 push. 활성 계획이 없으면 온보딩이 initialLocation.
  `bootstrapApp`이 기동 시 레거시 SharedPreferences 계획을 DB로 이관한다
- **몬테카를로** — `monteCarloRunnerProvider`가 `compute()`로 isolate 실행. 테스트는 동기 함수로 override
- **다국어** — 화면은 `context.l10n.<key>`(`lib/l10n/l10n.dart`), 컨텍스트가 없는 알림·위젯은
  `l10nFromSettings(store)`. 언어는 `localeProvider`(설정, null=기기 언어). 키는 그룹 접두어
  (`home*`, `sim*`, `pf*`, `goal*`/`onb*`, `snap*`, `settings*`, `paywall*`…), 공용은 `common*`/
  `disclaimer*`. ko 문구를 바꾸면 한국어 finder를 쓰는 테스트가 깨진다. 문구 변경 = 커밋 전
  `compliance-reviewer` 대상(세 언어 모두 검사)
- **통화 표기** — 금액은 항상 `moneyFormatOf(context, ref)`(`lib/features/common/money.dart`)로 그린다.
  금액 가림(●●●) 설정이 이 포매터에 내장돼 있어 `compact`/`full`이 자동으로 가려진다. 차트 축은
  `chartAmountLabel`이 가림 시 빈 라벨을 돌려준다.
  `compact`("1억 2,000만원"/"$1.23M"/"120万円") · `full` · 입력 필드 `inputPrefix`/`inputSuffix`.
  슬라이더·마일스톤·차트 축의 "사람에게 자연스러운 크기"는 `Currency.monthlyStep`/`netWorthTiers`/
  `chartAmountUnit`에서 나온다. 사용자 입력은 주 단위로 받고 `minorPerMajor`를 곱해 저장한다
- **테스트 인프라** — `test/helpers.dart`의 `appTest` + `pumpApp`이 in-memory Drift DB와 mock prefs로
  앱 전체를 띄운다(`seed` 콜백으로 계획/스냅샷 선삽입, `overrides`로 provider 교체). 위젯 테스트는
  반드시 `appTest`를 쓸 것 — drift 스트림 정리 타이머 때문에 `testWidgets`로 직접 쓰면 "Timer is still
  pending"으로 깨진다

## 제품 원칙 (기능 구현 시 판단 기준)

- 기록은 무료, 통찰(몬테카를로 상세·포트폴리오 비중 편집·시나리오 무제한 저장/비교)은 유료
- 행동 지시 금지: "리밸런싱하세요" X → "목표 대비 -5%p" O (투자자문 규제)
- 앱 문구에 '투자', '자산관리 서비스' 표현 지양 — '시뮬레이터/계산기/기록' (스토어 심사 3.2.1(viii) 오인 방지)
- 시뮬레이션 결과에는 "정보 제공 목적, 투자 자문 아님" 면책 유지
- 금액 표시는 가림 토글(●●●) 지원이 기본

## 미출시 기능을 노출하지 말 것 ★

**구현되지 않은 기능은 앱에도 스토어 문구에도 올리지 않는다.** 잠금(🔒)으로
보여주고 결제를 유도했는데 결제 후 열리지 않으면 오인 구매·환불·심사 리스크가 된다.
v1.0 준비 중 이 문제로 세 번 걸렸다(스토어 설명 2회, 자산 화면 연금·세제 탭 1회).
같은 뿌리의 네 번째 사고가 3.1.2(c) 리젝이다 — 아래 '구독 화면 필수 링크' 참조.

- 페이월(`paywall_sheet.dart`)에는 **지금 동작하는 기능만** 올린다.
  '출시 예정' 배지 기능(`comingSoon`)은 같은 실수를 막기 위해 아예 제거했다
- 미구현 기능은 진입점(탭·버튼) 자체를 만들지 않는다
- 스토어 문구의 기능 주장은 **빌드 산출물로 검증**한다 —
  절차는 `docs/guide/TestFlight_배포_가이드.md` §13

현재 프리미엄 3종은 모두 실제 동작한다: 몬테카를로 상세 분포 / 포트폴리오 비중
편집 / 시나리오 무제한 저장·나란히 비교. 미구현으로 남은 것은 **시퀀스 리스크
스트레스 테스트**와 **연금·세제 뷰**이며, 앱 어디에도 노출하지 않는다.

## 구독 화면 필수 링크 ★

App Store 지침 **3.1.2(c)**: 구독을 파는 앱은 이용약관(EULA)과 개인정보 처리방침
링크를 **앱 안(구독 화면)과 스토어 메타데이터 양쪽**에 둬야 한다. 빌드 6이 이걸로
리젝됐다. Apple 표준 EULA를 쓰더라도 링크 명시는 면제되지 않는다.

- 링크 상수는 `lib/features/paywall/paywall_sheet.dart`의 `paywallTermsUrl` /
  `paywallPrivacyUrl` 하나뿐 — 설정 화면도 이 상수를 가져다 쓴다
- **텍스트만 두면 안 되고 실제로 열려야 한다.** `premium_gate_test.dart`가
  `UrlLauncherPlatform`을 페이크로 갈아끼워 탭 → `launchUrl(url)` 호출까지 검증한다
- 스토어 설명 마지막 두 줄에도 같은 링크를 유지할 것 (`docs/스토어_등록_문구.md`)

## 릴리스 상태 (2026-09-23 기준)

- **v1.0 양대 스토어 게시 완료.** App Store는 빌드 8(0.1.0+8, 3.1.2(c) 대응 빌드),
  Google Play 프로덕션은 버전 6(0.1.0). 빌드 9(0.1.0+9)는 Play **내부 테스트 트랙**에만
  올라가 있다(설정 화면 고객 ID 타일). 현재 `pubspec.yaml`은 **`1.0.0+10`** — 다국어·다통화
  빌드. **2026-10-01 TestFlight 내부 테스트(알파테스터 그룹, 자동 배포)에 업로드**했고 심사
  제출은 아직이다. 설정 화면 앱 버전은 `package_info_plus`로 읽는다
- **iOS 업로드는 CLI로 한다.** `xcrun altool --upload-app --type ios -f build/ios/ipa/firedom.ipa
  --apiKey 8FZTAA3T77 --apiIssuer <Issuer ID>` (키는 `~/.appstoreconnect/private_keys/`, Issuer ID는
  메모리 `store-submission-setup`). 내부 그룹 '알파테스터'는 모든 빌드 자동 접근이라 처리 완료 즉시 뜬다
- **App Store 링크는 반드시 `kr` 스토어프론트로.** ASC 공유 버튼이 주는 `/us/` 링크는
  한국 단일 배포라 404가 난다. 공식 링크·단축 링크·배지는 `docs/스토어_등록_문구.md`
  '공용 URL'과 `docs/marketing/`에 있다
- **Play 내부 테스트 배포는 API로 한다.** `secret/`의 서비스 계정에 테스트 트랙 출시
  권한이 있어 edits → bundles 업로드 → tracks/internal → commit이 통과한다.
  내부 테스터 이메일 목록만 콘솔에서 직접 관리한다(API는 Google 그룹만 지원)
- **특정 사용자에게 결제 없이 프리미엄을 열어 줄 때**는 RevenueCat 대시보드의
  프로모셔널 엔타이틀먼트(`premium`, Lifetime)를 쓴다. 계정이 없는 앱이라 고객 ID가
  설치 단위 익명 ID이며, 설정 → 구독 → '고객 ID' 타일에서 복사할 수 있다(빌드 9~).
  앱을 삭제·재설치하면 ID가 바뀌므로 업데이트 설치로 유지해야 한다
- **배포 지역: 현재 스토어 게시본(빌드 8·9)은 대한민국만.** 2026-10-01에 글로벌 전환을
  결정해 코드는 ko·en·ja + KRW/USD/JPY를 지원하지만, **아직 다국어 빌드가 스토어에 올라가지
  않았다.** 국가 확장은 반드시 다국어 빌드 심사 통과 뒤 `docs/guide/TestFlight_배포_가이드.md`
  §14 순서로. 해외 앱 이름은 `Firedom`, 한국은 `파이어덤` 유지. 영어·일본어 등록정보는
  `docs/스토어_등록_문구.md` §5
- 구독 상품 ID는 양대 스토어 공통: `firedom_39000_1y`(₩39,000/년), `firedom_4900_1m`(₩4,900/월),
  각각 7일 무료 체험. **통화는 RevenueCat이 아니라 스토어가 정한다** — 앱은 RevenueCat이 주는
  현지화 가격 문자열(`storeProduct.priceString`)을 그대로 출력하므로 앱에 금액을 박지 않는다
- **양대 스토어 환산가가 어긋나 있다 (국가 확장 전 해결 필요).** 원화 기준가를 두 스토어가 각자
  환산해 같은 통화에서도 값이 다르다(미국 연간 App Store $22.99 vs Play $28.99). 맞추는 스크립트는
  `tool/align_play_prices.py`(드라이런 기본, `--apply`로 적용)이며 **실결제에 영향을 주므로 사람이
  직접 실행한다**. 실측 표와 주의사항은 `docs/스토어_등록_문구.md` §5-4
- **Play 서비스 계정은 읽기·트랙 출시만 가능하다.** 가격·상품 수정은 403 — Play Console에서
  해당 서비스 계정에 상품·가격 관리 권한을 먼저 켜야 한다 (AAB 업로드·내부 트랙 커밋은 지금도 된다)
- 스토어 API는 `tool/asc_api.py`(App Store Connect) / `tool/play_api.py`(Google Play) —
  외부 의존성 없이 서비스 계정·ASC 키로 토큰을 만든다. 자격증명은 `secret/`·`~/.appstoreconnect/`
- 빌드·제출 절차는 `docs/guide/TestFlight_배포_가이드.md`, 문구는 `docs/스토어_등록_문구.md`

## 비밀 파일 (커밋 금지)

`android/key.properties`, `android/app/upload-keystore.jks`, `revenuecat.json`,
`revenuecat.prod.json`, `secret/`, `*.p8` — 모두 gitignore 처리돼 있다.
새 자격증명을 추가할 때는 **먼저 `.gitignore`에 넣고** `git check-ignore -v`로 확인한다.

## 이 저장소의 Claude Code 설정

- `.claude/hooks/engine-tests.sh` — Edit/Write 후 엔진 골든 테스트 자동 실행
- `.claude/agents/compliance-reviewer.md` — 사용자 노출 문구 수정 후 커밋 전 실행
  (행동 지시 표현, 투자자문 오인 용어, 면책 누락, 금액 가림 미지원 검사)
- `.claude/skills/drift-migration/SKILL.md` — Drift 스키마 변경 절차

## 커밋 전 체크

- `fvm flutter analyze` 통과
- `fvm flutter test` 통과 (188개, 특히 engine 골든 테스트와 `l10n_smoke_test`)
- `lib/l10n/parts/*.json`을 고쳤다면 `python3 tool/merge_l10n.py && fvm flutter gen-l10n`을 돌려
  생성 파일까지 함께 커밋
- `lib/features/` 또는 `lib/l10n/parts/`의 사용자 노출 문구를 건드렸다면 `compliance-reviewer` 에이전트 실행 (ko·en·ja)
