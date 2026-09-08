# 파이어덤 (Firedom)

한국형 FIRE(조기은퇴) 시뮬레이터. **계산기가 아니라 궤도 추적기**를 지향한다 —
목표를 세우고 끝나는 게 아니라, 매달 자산을 기록하며 계획 대비 실제 궤도를 비교한다.

```
목표 설계 → 시뮬레이션(계획 궤도) → 월 1회 자산 스냅샷 → 계획 vs 실제 비교
```

- **플랫폼**: Flutter (iOS / Android), 번들ID `app.firedom.firedom`
- **아키텍처**: 로컬 우선, 서버리스 — 재무 데이터는 기기에만 저장되고 전송되지 않는다
- **현재 버전**: `0.1.0+3` — v1.0으로 App Store·Google Play 심사 제출됨 (2026-09-07)
- **배포 지역**: 대한민국 (한국어 단일 언어 앱)

## 기능

**무료**
- FIRE 나이·필요 자산 계산 (4% 룰 기반, 안전인출률 조정 가능)
- 결정론 시뮬레이션 차트 + What-if 슬라이더 (나이·순자산·저축액·수익률·은퇴 후 생활비)
- 월간 자산 스냅샷 기록, 저축률 추이, 지난 월 소급 편집
- 계획 vs 실제 궤도 비교, 마일스톤
- 홈 화면 위젯 (D-day·진행률, 금액 비노출) — **현재 Android만**, 월간 기록 리마인더
- 암호화 백업/복원, 금액 가림(●●●), 생체인증 앱 잠금, 다크 모드

**프리미엄 (구독)**
- 몬테카를로 시뮬레이션 — 성공 확률, 자산 고갈 나이 분포
- 포트폴리오 비중 자유 편집
- 시나리오 무제한 저장

> **iOS 홈 위젯도 아직 없다** — WidgetKit 익스텐션 타겟이 Xcode 프로젝트에 없어
> 빌드에 포함되지 않는다(`docs/W1_홈위젯_iOS_설정.md`의 1회 설정 미완). 그래서
> App Store 설명에서는 위젯을 빼고, Play 설명에만 넣는다.
>
> 시나리오 나란히 비교 · 시퀀스 리스크 스트레스 테스트 · 연금·세제 뷰는 **미출시**다.
> 앱 페이월에 `출시 예정` 배지로 표시되며, **스토어 문구에 넣지 않는다**
> (App Store 2.3.1 / Play 허위표시 정책). 자세한 건 `docs/스토어_등록_문구.md`.

## 시작하기

Flutter 버전은 fvm으로 고정한다 (`.fvmrc` → **3.44.5**). 항상 `fvm flutter ...`로 실행한다.

```bash
fvm install          # 최초 1회
fvm flutter pub get
fvm flutter run
```

- 에뮬레이터·시뮬레이터·실기기 실행: `docs/guide/로컬_실행_가이드.md`
- iOS 홈 위젯은 Xcode에서 Extension 타겟을 1회 수동 추가해야 한다: `docs/W1_홈위젯_iOS_설정.md`
- 결제를 붙여 테스트하려면 `revenuecat.json`(git 제외)에 키를 넣고
  `--dart-define-from-file=revenuecat.json`로 주입한다. 예시는 `revenuecat.json.example`.

## 검증

```bash
fvm flutter analyze   # 통과 필수
fvm flutter test      # 통과 필수 (156개)
```

시뮬레이션 엔진(`lib/engine/`)은 순수 Dart 모듈이고, 엑셀 검증 기준 케이스에 대한
골든 테스트로 오차 <0.1%를 유지한다. `lib/engine/` 수정 시 `.claude/hooks/engine-tests.sh`
훅이 자동으로 엔진 테스트를 돌린다.

## 구조

```
lib/
  app/          앱 셸 — 테마, 라우터(go_router), 앱 잠금, 인앱 업데이트
  core/         공용 유틸
  data/         Drift(SQLite) 스키마·리포지토리, 알림, 홈 위젯 동기화
  engine/       ★ 순수 Dart 시뮬레이션 엔진 (Flutter 의존성 없음)
                deterministic · monte_carlo · portfolio · tracking · milestones
  features/     화면 단위 — onboarding, home, simulation, snapshot,
                assets, goal, paywall, settings, lock
test/           위젯·플로우 테스트 + engine 골든 테스트
docs/           기획·설계·운영 문서
store_assets/   스토어 제출용 스크린샷·피처 그래픽·아이콘 (git 미포함 자산 포함)
```

주요 의존성: `flutter_riverpod` · `go_router` · `drift` · `fl_chart` ·
`purchases_flutter`(RevenueCat) · `home_widget` · `flutter_local_notifications` ·
`local_auth` · `cryptography` · `upgrader`

## 문서

| 문서 | 내용 |
|---|---|
| `CLAUDE.md` | 아키텍처 결정·제품 원칙 — **작업 전 필독** |
| `docs/PRD_FIRE시뮬레이터_MVP.md` | 화면 단위 스펙, 로드맵 |
| `docs/엔진명세_스키마설계.md` | 시뮬레이션 수식·DB 스키마 |
| `docs/경쟁분석_FIRE재무설계앱.md` | 포지셔닝 근거 |
| `docs/Firedom_브랜드_ASO.md` | 네이밍·ASO 전략 |
| `docs/자산군_프리셋_근거.md` | 수익률·변동성 프리셋 출처 |
| `docs/스토어_등록_문구.md` | 스토어 등록 문구 최종안, 심사 주의사항 |
| `docs/guide/로컬_실행_가이드.md` | 로컬 실행·디버깅 |
| `docs/guide/TestFlight_배포_가이드.md` | 베타·정식 빌드 및 배포 |
| `docs/W1_홈위젯_iOS_설정.md` | iOS WidgetKit 설정 |

## 비밀 파일 (커밋 금지)

아래는 모두 `.gitignore` 처리돼 있다. **특히 Android 업로드 키스토어는 분실 시 복구가
불가능하므로 반드시 별도 백업할 것.**

```
android/key.properties            android/app/upload-keystore.jks
revenuecat.json                   revenuecat.prod.json
secret/                           *.p8
```

## 라이선스

비공개 프로젝트 (`publish_to: none`). © 2026 Pink Spider
