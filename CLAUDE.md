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

- 기록은 무료, 통찰(몬테카를로 상세·포트폴리오 비중 편집·시나리오 무제한 저장)은 유료
- 행동 지시 금지: "리밸런싱하세요" X → "목표 대비 -5%p" O (투자자문 규제)
- 앱 문구에 '투자', '자산관리 서비스' 표현 지양 — '시뮬레이터/계산기/기록' (스토어 심사 3.2.1(viii) 오인 방지)
- 시뮬레이션 결과에는 "정보 제공 목적, 투자 자문 아님" 면책 유지
- 금액 표시는 가림 토글(●●●) 지원이 기본

## 미출시 기능을 광고하지 말 것 ★

페이월(`lib/features/paywall/paywall_sheet.dart`)에서 `comingSoon: true`로 표시되는 기능
— **시나리오 나란히 비교 · 시퀀스 리스크 스트레스 테스트 · 연금·세제 뷰** — 은
아직 구현되지 않았다. 스토어 설명·구독 설명·마케팅 문구에 **판매 문구로 넣지 말 것**
(App Store 2.3.1 부정확한 메타데이터 / Play 허위표시 정책 위반).
기능이 출시되면 페이월 배지를 떼면서 `docs/스토어_등록_문구.md`도 함께 갱신한다.

## 릴리스 상태 (2026-09-08 기준)

- 버전 `0.1.0+3`, v1.0으로 **App Store·Google Play 심사 제출 완료** (2026-09-07)
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
- `fvm flutter test` 통과 (156개, 특히 engine 골든 테스트)
- `lib/features/`의 사용자 노출 문구를 건드렸다면 `compliance-reviewer` 에이전트 실행
