# Firedom (파이어덤)

한국형 FIRE(조기은퇴) 시뮬레이터 앱. 핵심 루프: 목표 설계 → 시뮬레이션(계획 궤도) → 월 1회 자산 스냅샷 기록 → 계획 vs 실제 궤도 비교.

상세 기획은 `docs/PRD_FIRE시뮬레이터_MVP.md`(화면 단위 스펙), `docs/경쟁분석_FIRE재무설계앱.md`, `docs/Firedom_브랜드_ASO.md` 참조.

## 스택 / 명령어

- Flutter (fvm으로 버전 고정 — `.fvmrc`의 3.44.5, 항상 `fvm flutter ...` 사용)
- 로컬 DB: SQLite(Drift). 서버 없음(MVP는 완전 로컬, 계정 없음)
- 결제: 스토어 IAP + RevenueCat. **entitlement는 `premium` 고정** (`lib/data/entitlements.dart`)
- 실행: `fvm flutter run` / 테스트: `fvm flutter test`
- 번들ID/패키지: `app.firedom.firedom`
- iOS 서명: Xcode 자동 서명, 팀 `Z53YTTRR32`
- Android 서명: 업로드 키스토어 `android/app/upload-keystore.jks` + `android/key.properties`
  (둘 다 git 제외). `key.properties`가 없으면 릴리스 빌드가 디버그 서명으로 폴백한다 —
  **분실 시 복구 불가라 백업 필수**

## 아키텍처 결정 (변경 시 반드시 논의)

- **로컬 우선, 서버리스**: 재무 데이터는 기기에만 저장. 어떤 네트워크 전송 코드도 추가 금지 (v1.x 동기화 서버는 별도 결정)
- **시뮬레이션 엔진은 순수 Dart 모듈** (`lib/engine/`): Flutter/UI 의존성 금지. 엑셀 검증 기준 케이스와 골든 테스트 유지, 오차 <0.1%
- **동기화 대비 스키마 규칙**: 모든 테이블 UUID PK(auto-increment 금지), `created_at`/`updated_at`, soft delete(`deleted_at`)
- **금액은 정수(원 단위)**: double/부동소수점으로 금액 표현 금지
- 몬테카를로는 Dart isolate에서 실행 (UI 블로킹 금지), 시드 고정 옵션 유지

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
  Google Play 프로덕션은 버전 6(0.1.0). 현재 `pubspec.yaml`은 `0.1.0+9`이고
  빌드 9는 Play **내부 테스트 트랙**에만 올라가 있다(설정 화면 고객 ID 타일)
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
- **배포 지역은 대한민국만.** 한국어 단일 등록정보이고 국민연금·원화 기준 기능이라
  전 세계 배포는 부적절 — 국가를 넓히려면 먼저 논의할 것
- 구독 상품 ID는 양대 스토어 공통: `firedom_39000_1y`(₩39,000/년), `firedom_4900_1m`(₩4,900/월),
  각각 7일 무료 체험
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
- `fvm flutter test` 통과 (159개, 특히 engine 골든 테스트)
- `lib/features/`의 사용자 노출 문구를 건드렸다면 `compliance-reviewer` 에이전트 실행
