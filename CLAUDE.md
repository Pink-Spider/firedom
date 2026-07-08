# Firedom (파이어덤)

한국형 FIRE(조기은퇴) 시뮬레이터 앱. 핵심 루프: 목표 설계 → 시뮬레이션(계획 궤도) → 월 1회 자산 스냅샷 기록 → 계획 vs 실제 궤도 비교.

상세 기획은 `docs/PRD_FIRE시뮬레이터_MVP.md`(화면 단위 스펙), `docs/경쟁분석_FIRE재무설계앱.md`, `docs/Firedom_브랜드_ASO.md` 참조.

## 스택 / 명령어

- Flutter (fvm으로 버전 고정 — 항상 `fvm flutter ...` 사용)
- 로컬 DB: SQLite(Drift). 서버 없음(MVP는 완전 로컬, 계정 없음)
- 결제: 스토어 IAP + RevenueCat
- 실행: `fvm flutter run` / 테스트: `fvm flutter test`
- iOS 서명: Apple Development 인증서 (T3ZCY59BDJ) 사용, Xcode 자동 서명
- 번들ID/패키지: `app.firedom.firedom`

## 아키텍처 결정 (변경 시 반드시 논의)

- **로컬 우선, 서버리스**: 재무 데이터는 기기에만 저장. 어떤 네트워크 전송 코드도 추가 금지 (v1.x 동기화 서버는 별도 결정)
- **시뮬레이션 엔진은 순수 Dart 모듈** (`lib/engine/`): Flutter/UI 의존성 금지. 엑셀 검증 기준 케이스와 골든 테스트 유지, 오차 <0.1%
- **동기화 대비 스키마 규칙**: 모든 테이블 UUID PK(auto-increment 금지), `created_at`/`updated_at`, soft delete(`deleted_at`)
- **금액은 정수(원 단위)**: double/부동소수점으로 금액 표현 금지
- 몬테카를로는 Dart isolate에서 실행 (UI 블로킹 금지), 시드 고정 옵션 유지

## 제품 원칙 (기능 구현 시 판단 기준)

- 기록은 무료, 통찰(몬테카를로 상세·시나리오 비교·연금 뷰)은 유료
- 행동 지시 금지: "리밸런싱하세요" X → "목표 대비 -5%p" O (투자자문 규제)
- 앱 문구에 '투자', '자산관리 서비스' 표현 지양 — '시뮬레이터/계산기/기록' (스토어 심사 3.2.1(viii) 오인 방지)
- 시뮬레이션 결과에는 "정보 제공 목적, 투자 자문 아님" 면책 유지
- 금액 표시는 가림 토글(●●●) 지원이 기본

## 커밋 전 체크

- `fvm flutter analyze` 통과
- `fvm flutter test` 통과 (특히 engine 골든 테스트)
